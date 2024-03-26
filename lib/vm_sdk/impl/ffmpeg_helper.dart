import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:uuid/uuid.dart';

import '../types/types.dart';
import 'global_helper.dart';
import 'ffmpeg_manager.dart';

Resolution _resolution = Resolution(0, 0);
int _scaledVideoWidth = 0;
int _scaledVideoHeight = 0;
int _framerate = 30;
ERatio _ratio = ERatio.ratio11;

double _scaleFactor = 2 / 3.0;
double _minDurationFactor = 1 / _framerate;
// const int _fadeDuration = 3;
const int _fadeDuration = 0;

class RenderedData {
  String absolutePath;
  double duration;

  RenderedData(this.absolutePath, this.duration);
}

final FFMpegManager _ffmpegManager = FFMpegManager();

String _getTransposeFilter(int orientation) {
  // switch (orientation) {
  //   case 90: return "transpose=1,";
  //   case 180: return "transpose=2,transpose=2,";
  //   case 270: return "transpose=2,";
  //   default: return "";
  // }
  return "";
}

int _getEvenNumber(int num) {
  num -= (num % 2);
  return num;
}

void setRatio(ERatio ratio) {
  _ratio = ratio;
  _resolution = Resolution.fromRatio(ratio);

  _scaledVideoWidth = _getEvenNumber((_resolution.width * _scaleFactor).floor());
  _scaledVideoHeight = _getEvenNumber((_resolution.height * _scaleFactor).floor());
}

Future<RenderedData> clipRender(
    EditedMedia editedMedia,
    int clipIdx,
    TransitionData? prevTransition,
    TransitionData? nextTransition,
    Function(Statistics)? ffmpegCallback, { isOnlyOneClip = false }) async {
  final MediaData mediaData = await scaleImageMedia(editedMedia.mediaData);
  final FrameData? frame = editedMedia.frame;
  final List<EditedStickerData> stickerList = editedMedia.stickers;
  final List<CanvasTextData> canvasTexts = editedMedia.canvasTexts;
  final List<EditedTextData> textList = editedMedia.editedTexts;

  double duration =
      normalizeTime(editedMedia.duration + editedMedia.xfadeDuration);
  double startTime = normalizeTime(editedMedia.startTime);

  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/clip$clipIdx.mp4";

  final List<String> inputArguments = <String>[]; // -i arguments
  final List<String> filterStrings = <String>[]; // -filter_complex strings

  int inputFileCount = 0;
  String trimFilter = "";
  String videoOutputMapVariable = "";
  String audioOutputMapVariable = "";

  /////////////////////////
  // INPUT IMAGE & VIDEO //
  /////////////////////////
  if (mediaData.type == EMediaType.image) {
    inputArguments
        .addAll(["-framerate", "$_framerate", "-loop", "1"]);
    inputArguments.addAll(["-t", "$duration", "-i", mediaData.scaledPath ?? mediaData.absolutePath]);

    audioOutputMapVariable = "1:a";
  } //
  else {
    trimFilter = "trim=$startTime:${startTime + duration},setpts=PTS-STARTPTS,";
    inputArguments
        .addAll(["-i", mediaData.absolutePath]);

    final mediaInfo = (await FFprobeKit.getMediaInformation(mediaData.absolutePath)).getMediaInformation();
    final List<StreamInformation> streams = mediaInfo != null ? mediaInfo.getStreams() : [];

    bool isAudioExists = false;
    for (final stream in streams) {
      if (stream.getType() == "audio") {
        isAudioExists = true;
        break;
      }
    }

    if (isAudioExists) {
      filterStrings.add(
        "[0:a]atrim=$startTime:${startTime + duration},asetpts=PTS-STARTPTS[aud];[aud][1:a]amix=inputs=2[aud_mixed];[aud_mixed]atrim=0:$duration,asetpts=PTS-STARTPTS[aud_trim];[aud_trim]volume=${editedMedia.volume}[aud_volume_applied];");
      audioOutputMapVariable = "[aud_volume_applied]";
    }
    else {
      audioOutputMapVariable = "1:a";
    }
  }

  // [1:a]
  inputArguments.addAll([
    "-f",
    "lavfi",
    "-t",
    duration.toString(),
    "-i",
    "anullsrc=channel_layout=stereo:sample_rate=44100"
  ]);
  inputFileCount++;


  // Retrieve the scale factor from the edited media
  double scale = editedMedia.scale;

  // Determine if the clip's dimensions have changed due to rotation (90 or 270 degrees) and swap width, height accordingly
  bool clipDimensionChanged = [90.0, 270.0].contains(editedMedia.angle);
  int clipWidth = clipDimensionChanged ? mediaData.height : mediaData.width;
  int clipHeight = clipDimensionChanged ? mediaData.width : mediaData.height;

  // Target resolution width and height
  // Because the logic is aiming to fit the clip entirely in video frame => visible width and height always same as _resolution
  int xWidth = _resolution.width;
  int xHeight = _resolution.height;

  // Calculate the aspect ratio of both the media and the target resolution
  double xMediaRatio = clipWidth / clipHeight;
  double resolutionRatio = _resolution.width / _resolution.height;

  // Determine if the media should fit by height based on aspect ratios
  bool fitHeight = xMediaRatio > resolutionRatio;

  // Initialize a variable for calculating scale error margin
  double resolutionErrorMargin = 1;

  // Adjust scale based on whether the media fits by height or width. For e.g: 3444:1440 fit in 1920:1080 by default scale down by 1.333333333333
  if(xMediaRatio > resolutionRatio){
    resolutionErrorMargin = clipWidth / (_resolution.width * xMediaRatio);
  } else {
    resolutionErrorMargin = clipWidth / _resolution.width;
  }
  scale = scale / resolutionErrorMargin;

  // Adjust the width or height based on the fitting requirement
  if(fitHeight){
    xWidth = (xHeight * resolutionRatio).floor();
  } else {
    xHeight = (xWidth / resolutionRatio).floor();
  }

  // Calculate crop dimensions based on edited media properties
  int cropLeft = (xWidth * editedMedia.cropLeft).floor();
  int cropRight = (xWidth * editedMedia.cropRight).floor();
  int cropTop = (xHeight * editedMedia.cropTop).floor();
  int cropBottom = (xHeight * editedMedia.cropBottom).floor();
  int cropWidth = cropRight - cropLeft;
  int cropHeight = cropBottom - cropTop;

  // Prepare the flip and rotate filters based on edited media properties
  String flipString = '';
  String? rotateString = '';
  if(editedMedia.hFlip){
    flipString = 'hflip,';
  }
  if(editedMedia.vFlip){
    flipString = '${flipString}vflip,';
  }

  // Prepare the rotation string, adjusting for possible dimension changes
  String rotateModifyStr = clipDimensionChanged ? ':out_w=in_h:out_h=in_w' : '';
  rotateString = 'rotate=${editedMedia.angle * (pi / 180)}$rotateModifyStr,';

  // Construct the FFmpeg filter string using the prepared parameters
  String args = "[0:v]fps=$_framerate,$trimFilter${_getTransposeFilter(mediaData.orientation)}${flipString}scale=${mediaData.width * scale}:${mediaData.height * scale},${rotateString}crop=$cropWidth:$cropHeight:$cropLeft:$cropTop,setdar=dar=${_resolution.width / _resolution.height}[vid];";

  filterStrings.add(args);
  videoOutputMapVariable = "[vid]";
  inputFileCount++;
  
  ///////////////
  // ADD FRAME //
  ///////////////

  if (frame != null) {
    ResourceFileInfo fileInfo = frame.fileMap[_ratio]!;

    final int loopCount = (duration / fileInfo.duration).floor();
    const String frameMapVariable = "[frame]";
    const String frameMergedMapVariable = "[frame_merged]";

    inputArguments.addAll([
      "-stream_loop",
      loopCount.toString(),
      "-c:v",
      "libvpx-vp9",
      "-i",
      "$appDirPath/${fileInfo.source.name}"
    ]);

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${_resolution.width}:${_resolution.height},setdar=dar=${_resolution.width / _resolution.height}$frameMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${frameMapVariable}overlay$frameMergedMapVariable;");

    videoOutputMapVariable = frameMergedMapVariable;
  }

  /////////////////
  // ADD STICKER //
  /////////////////

  for (int i = 0; i < stickerList.length; i++) {
    final EditedStickerData sticker = stickerList[i];
    ResourceFileInfo fileInfo = sticker.fileinfo!;

    final int loopCount = (duration / fileInfo.duration).floor();
    final String stickerMapVariable = "[sticker$i]";
    final String stickerScaledMapVariable = "[sticker_scaled$i]";
    final String stickerRotatedMapVariable = "[sticker_rotated$i]";
    final String stickerMergedMapVariable = "[sticker_merged$i]";

    double rotate = sticker.rotate;
    if (rotate < 0) rotate = pi + (pi + rotate);

    double rotateForCal = rotate;
    if (rotateForCal > pi) rotateForCal -= pi;
    if (rotateForCal > pi / 2) rotateForCal = (pi / 2) - (rotateForCal - (pi / 2));

    inputArguments.addAll([
      "-stream_loop",
      loopCount.toString(),
      "-c:v",
      "libvpx-vp9",
      "-i",
      "$appDirPath/${fileInfo.source.name}"
    ]);

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS$stickerMapVariable;");
    filterStrings.add(
        "${stickerMapVariable}scale=${sticker.width}:${sticker.height}$stickerScaledMapVariable;");
    filterStrings.add(
        "${stickerScaledMapVariable}rotate=$rotate:c=none:ow=rotw($rotate):oh=roth($rotate)$stickerRotatedMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${stickerRotatedMapVariable}overlay=${sticker.x}-(((${sticker.width}*cos($rotateForCal)+${sticker.height}*sin($rotateForCal))-${sticker.width})/2):${sticker.y}-(((${sticker.width}*sin($rotateForCal)+${sticker.height}*cos($rotateForCal))-${sticker.height})/2)$stickerMergedMapVariable;");

    videoOutputMapVariable = stickerMergedMapVariable;
  }

  /////////////////////
  // ADD CANVAS TEXT //
  /////////////////////

  for (int i = 0; i < canvasTexts.length; i++) {
    final CanvasTextData canvasText = canvasTexts[i];

    final String canvasTextScaledMapVariable = "[canvas_text_scaled$i]";
    final String canvasTextRotatedMapVariable = "[canvas_text_rotated$i]";
    final String canvasTextMergedMapVariable = "[canvas_text_merged$i]";

    double rotate = canvasText.rotate;
    if (rotate < 0) rotate = pi + (pi + rotate);

    double rotateForCal = rotate;
    if (rotateForCal > pi) rotateForCal -= pi;
    if (rotateForCal > pi / 2) rotateForCal = (pi / 2) - (rotateForCal - (pi / 2));

    inputArguments.addAll([
      "-i",
      canvasText.imagePath
    ]);

    String overlayTimeFilter = "";
    if (isOnlyOneClip) {
      // overlayTimeFilter = "enable='between(t\\,0,${min(5, editedMedia.duration)})':";
    }

    filterStrings.add(
        "[${inputFileCount++}:v]scale=${canvasText.width}:-1$canvasTextScaledMapVariable;");
    filterStrings.add(
        "${canvasTextScaledMapVariable}rotate=$rotate:c=none:ow=rotw($rotate):oh=roth($rotate)$canvasTextRotatedMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${canvasTextRotatedMapVariable}overlay=${overlayTimeFilter}x=${canvasText.x}-(((${canvasText.width}*cos($rotateForCal)+${canvasText.height}*sin($rotateForCal))-${canvasText.width})/2):y=${canvasText.y}-(((${canvasText.width}*sin($rotateForCal)+${canvasText.height}*cos($rotateForCal))-${canvasText.height})/2)$canvasTextMergedMapVariable;");

    videoOutputMapVariable = canvasTextMergedMapVariable;
  }

  ///////////////
  // ADD TITLE //
  ///////////////

  for (int i = 0; i < textList.length; i++) {
    final EditedTextData editedText = textList[i];
    final TextExportData? exportedText = editedText.textExportData;

    if (exportedText != null) {
      String textMapVariable = "[text$i]";
      String textRotatedMapVariable = "[text_rotated$i]";
      String textMergedMapVariable = "[text_merged$i]";

      double rotate = editedText.rotate;
      if (rotate < 0) rotate = pi + (pi + rotate);

      double rotateForCal = rotate;
      if (rotateForCal > pi) rotateForCal -= pi;
      if (rotateForCal > pi / 2) rotateForCal = (pi / 2) - (rotateForCal - (pi / 2));

      int width = (editedText.width).floor();
      int height = (editedText.height).floor();

      inputArguments.addAll([
        "-framerate",
        exportedText.frameRate.toString(),
        "-i",
        "${exportedText.allSequencesPath}/%d.png"
      ]);

      String overlayTimeFilter = "";
      if (isOnlyOneClip) {
        overlayTimeFilter = "enable='between(t\\,0,${min(5, editedMedia.duration)})':";
      }

      filterStrings.add(
          "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=$width:-1$textMapVariable;");
      filterStrings.add(
          "${textMapVariable}rotate=$rotate:c=none:ow=rotw($rotate):oh=roth($rotate)$textRotatedMapVariable;");
      filterStrings.add(
          "$videoOutputMapVariable${textRotatedMapVariable}overlay=${overlayTimeFilter}x=${editedText.x}-((($width*cos($rotateForCal)+$height*sin($rotateForCal))-$width)/2):y=${editedText.y}-((($width*sin($rotateForCal)+$height*cos($rotateForCal))-$height)/2)$textMergedMapVariable;");

      videoOutputMapVariable = textMergedMapVariable;
    }
  }

  ////////////////////////////
  // ADD OVERLAY TRANSITION //
  ////////////////////////////

  if (prevTransition != null &&
      prevTransition.type == ETransitionType.overlay) {
    final OverlayTransitionData transitionData =
        prevTransition as OverlayTransitionData;
    final TransitionFileInfo fileInfo = transitionData.fileMap[_ratio]!;

    String transitionMapVariable = "[prev_trans]";
    String transitionMergedMapVariable = "[prev_trans_merged]";

    inputArguments.addAll(
        ["-c:v", "libvpx-vp9", "-i", "$appDirPath/${fileInfo.source.name}"]);
    filterStrings.add(
        "[${inputFileCount++}:v]trim=${fileInfo.transitionPoint}:${fileInfo.duration},setpts=PTS-STARTPTS,scale=${_resolution.width}:${_resolution.height},setdar=dar=${_resolution.width / _resolution.height}$transitionMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${transitionMapVariable}overlay=enable='between(t\\,0,${fileInfo.duration - fileInfo.transitionPoint})'$transitionMergedMapVariable;");
    videoOutputMapVariable = transitionMergedMapVariable;
  }

  if (nextTransition != null &&
      nextTransition.type == ETransitionType.overlay) {
    final OverlayTransitionData transitionData =
        nextTransition as OverlayTransitionData;
    final TransitionFileInfo fileInfo = transitionData.fileMap[_ratio]!;

    String transitionMapVariable = "[next_trans]";
    String transitionMergedMapVariable = "[next_trans_merged]";

    inputArguments.addAll([
      "-c:v",
      "libvpx-vp9",
      "-itsoffset",
      (duration - fileInfo.transitionPoint).toString(),
      "-i",
      "$appDirPath/${fileInfo.source.name}"
    ]);
    filterStrings.add(
        "[${inputFileCount++}:v]scale=${_resolution.width}:${_resolution.height},setdar=dar=${_resolution.width / _resolution.height}$transitionMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${transitionMapVariable}overlay=enable='between(t\\,${duration - fileInfo.transitionPoint},$duration)'$transitionMergedMapVariable;");
    videoOutputMapVariable = transitionMergedMapVariable;
  }

  filterStrings.add(
      "${videoOutputMapVariable}trim=0:$duration,setpts=PTS-STARTPTS[trim_vid];");
  videoOutputMapVariable = "[trim_vid]";

  filterStrings.add(
      "${videoOutputMapVariable}scale=$_scaledVideoWidth:$_scaledVideoHeight,setdar=dar=${_scaledVideoWidth / _scaledVideoHeight}[out_vid];");
  videoOutputMapVariable = "[out_vid]";

  // generate -filter_complex
  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  String inputArgumentsStr = "";
  for (final String inputStr in inputArguments) {
    inputArgumentsStr += inputStr + ',';
  }

  if (filterComplexStr.endsWith(";")) {
    filterComplexStr =
        filterComplexStr.substring(0, filterComplexStr.length - 1);
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([
    "-map",
    videoOutputMapVariable,
    "-map",
    audioOutputMapVariable,
    "-c:v",
    "libx264",
    "-preset",
    "superfast",
    "-c:a",
    "aac",
    "-b:a",
    "256k",
    "-maxrate",
    "5M",
    "-bufsize",
    "5M",
    "-pix_fmt",
    "yuv420p",
    "-r",
    _framerate.toString(),
    "-shortest",
    outputPath,
    "-y"
  ]);

  await _ffmpegManager.execute(arguments, ffmpegCallback);
  return RenderedData(outputPath, duration);
}

Future<RenderedData> applyXFadeTransitions(
    RenderedData curClip,
    RenderedData nextClip,
    int clipIdx,
    String xfadeKey,
    double xfadeDuration,
    Function(Statistics)? ffmpegCallback) async {
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/xfade_merged$clipIdx.mp4";

  final double xfadeOffset =
      normalizeTime(curClip.duration - xfadeDuration - 0.01);
  double duration = normalizeTime(
      curClip.duration + nextClip.duration - xfadeDuration - 0.01);

  String filterComplexStr = "";
  filterComplexStr +=
      "[0:v][1:v]xfade=transition=$xfadeKey:duration=$xfadeDuration:offset=$xfadeOffset[trans_applied];[trans_applied]trim=0:$duration,setpts=PTS-STARTPTS[vid];";
  filterComplexStr +=
      "[1:a]adelay=${(xfadeOffset * 1000).floor()}|${(xfadeOffset * 1000).floor()}[delayed];";
  filterComplexStr +=
      "[0:a][delayed]amix=inputs=2:dropout_transition=99999,volume=2[aud]";

  await _ffmpegManager.execute([
    "-i",
    curClip.absolutePath,
    "-i",
    nextClip.absolutePath,
    "-filter_complex",
    filterComplexStr,
    "-map",
    "[vid]",
    "-map",
    "[aud]",
    "-c:v",
    "libx264",
    "-preset",
    "superfast",
    "-c:a",
    "aac",
    "-b:a",
    "256k",
    "-maxrate",
    "5M",
    "-bufsize",
    "5M",
    "-pix_fmt",
    "yuv420p",
    "-r",
    _framerate.toString(),
    outputPath,
    "-y"
  ], ffmpegCallback);
  return RenderedData(outputPath, duration);
}

Future<RenderedData> applyFadeOut(List<RenderedData> clips) async {
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/fade_out_applied.mp4";

  final List<String> arguments = [];
  final List<String> inputArguments = [];
  String filterComplexStr = "";

  double totalDuration = 0;
  for (int i = 0; i < clips.length; i++) {
    RenderedData clip = clips[i];

    inputArguments.addAll(["-i", clip.absolutePath]);

    filterComplexStr += "[$i]";
    totalDuration += clip.duration;
  }

  filterComplexStr +=
      "concat=n=${clips.length}:v=1:a=1[outv][outa];[outv]fade=t=out:st=${totalDuration - 1.5}:d=1.5[faded]";

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([
    "-map",
    "[faded]",
    "-map",
    "[outa]",
    "-c:v",
    "libx264",
    "-preset",
    "superfast",
    "-c:a",
    "aac",
    "-b:a",
    "256k",
    "-maxrate",
    "5M",
    "-bufsize",
    "5M",
    "-pix_fmt",
    "yuv420p",
    "-r",
    _framerate.toString(),
    outputPath,
    "-y"
  ]);
  await _ffmpegManager.execute(arguments, null);
  return RenderedData(outputPath, totalDuration);
}

Future<RenderedData> mergeAllClips(List<RenderedData> clipList) async {
  final String appDirPath = await getAppDirectoryPath();

  List<RenderedData> fileredClipList = [];
  for (int i = 0; i < clipList.length; i++) {
    final RenderedData clip = clipList[i];
    if (clip.duration > 0) fileredClipList.add(clip);
  }

  List<RenderedData> mergedClipList = [];
  List<RenderedData> currentList = [];

  final File mergeTextFile = File("$appDirPath/merge.txt");
  double totalDuration = 0;

  for (int i = 0; i < fileredClipList.length; i++) {
    final RenderedData clipData = fileredClipList[i];
    currentList.add(clipData);
    totalDuration += clipData.duration;

    if (currentList.length >= 50 || i == fileredClipList.length - 1) {
      final String videoOutputPath =
          "$appDirPath/part_merged_video${mergedClipList.length}.mp4";
      final String audioOutputPath =
          "$appDirPath/part_merged_audio${mergedClipList.length}.m4a";
      final String mergeOutputPath =
          "$appDirPath/part_merged_all${mergedClipList.length}.mp4";
      double mergedDuration = 0;

      if (currentList.length == 1) {
        mergedDuration += currentList[0].duration;
        await _ffmpegManager.execute([
          "-i",
          currentList[0].absolutePath,
          "-map",
          "0:v",
          "-c:v",
          "copy",
          videoOutputPath,
          "-y"
        ], null);

        await _ffmpegManager.execute([
          "-i",
          currentList[0].absolutePath,
          "-map",
          "0:a",
          "-c:a",
          "copy",
          audioOutputPath,
          "-y"
        ], null);
      } //
      else {
        List<String> audioArguments = [];

        String videoMergeTargets = "";
        String audioMergeTargets = "";
        String audioFilterComplexStr = "";

        int currentDurationMS = 0;
        for (int j = 0; j < currentList.length; j++) {
          videoMergeTargets += "file '${currentList[j].absolutePath}'\n";
          mergedDuration += currentList[j].duration;

          String audioOutputVariable = "[aud$j]";
          audioArguments.addAll(["-i", currentList[j].absolutePath]);
          audioFilterComplexStr +=
              "[$j:a]atrim=0:${currentList[j].duration},asetpts=PTS-STARTPTS,adelay=$currentDurationMS|$currentDurationMS$audioOutputVariable;";
          audioMergeTargets += audioOutputVariable;

          currentDurationMS += (currentList[j].duration * 1000).floor();
        }
        await mergeTextFile.writeAsString(videoMergeTargets);

        await _ffmpegManager.execute([
          "-f",
          "concat",
          "-safe",
          "0",
          "-i",
          mergeTextFile.path,
          "-c",
          "copy",
          videoOutputPath,
          "-y"
        ], null);

        audioFilterComplexStr +=
            "${audioMergeTargets}amix=inputs=${currentList.length}:dropout_transition=99999,volume=${currentList.length}[out]";
        audioArguments.addAll([
          "-filter_complex",
          audioFilterComplexStr,
          "-map",
          "[out]",
          "-c:a",
          "aac",
          "-b:a",
          "256k",
          audioOutputPath,
          "-y"
        ]);

        await _ffmpegManager.execute(audioArguments, null);
      }

      await _ffmpegManager.execute([
        "-i",
        videoOutputPath,
        "-i",
        audioOutputPath,
        "-map",
        "0:v",
        "-map",
        "1:a",
        "-c",
        "copy",
        mergeOutputPath,
        "-y"
      ], null);

      mergedClipList.add(RenderedData(mergeOutputPath, mergedDuration));
      currentList = [];
    }
  }

  final String videoOutputPath = "$appDirPath/allclip_merged_video.mp4";
  final String audioOutputPath = "$appDirPath/allclip_merged_audio.m4a";
  final String mergeOutputPath = "$appDirPath/allclip_merged_all.mp4";

  if (mergedClipList.length == 1) {
    await _ffmpegManager.execute([
      "-i",
      mergedClipList[0].absolutePath,
      "-map",
      "0:v",
      "-c:v",
      "copy",
      videoOutputPath,
      "-y"
    ], null);

    await _ffmpegManager.execute([
      "-i",
      mergedClipList[0].absolutePath,
      "-map",
      "0:a",
      "-c:a",
      "copy",
      audioOutputPath,
      "-y"
    ], null);
  } //
  else {
    List<String> audioArguments = [];

    String videoMergeTargets = "";
    String audioMergeTargets = "";
    String audioFilterComplexStr = "";

    int currentDurationMS = 0;
    for (int j = 0; j < mergedClipList.length; j++) {
      videoMergeTargets += "file '${mergedClipList[j].absolutePath}'\n";

      String audioOutputVariable = "[aud$j]";
      audioArguments.addAll(["-i", mergedClipList[j].absolutePath]);
      audioFilterComplexStr +=
          "[$j:a]atrim=0:${mergedClipList[j].duration},asetpts=PTS-STARTPTS,adelay=$currentDurationMS|$currentDurationMS$audioOutputVariable;";
      audioMergeTargets += audioOutputVariable;

      currentDurationMS += (mergedClipList[j].duration * 1000).floor();
    }
    await mergeTextFile.writeAsString(videoMergeTargets);

    await _ffmpegManager.execute([
      "-f",
      "concat",
      "-safe",
      "0",
      "-i",
      mergeTextFile.path,
      "-c",
      "copy",
      videoOutputPath,
      "-y"
    ], null);

    audioFilterComplexStr +=
        "${audioMergeTargets}amix=inputs=${mergedClipList.length}:dropout_transition=99999,volume=${mergedClipList.length / 2}[merged];[merged]afade=t=out:st=${max(totalDuration - _fadeDuration, 0)}:d=$_fadeDuration[out]";
    audioArguments.addAll([
      "-filter_complex",
      audioFilterComplexStr,
      "-map",
      "[out]",
      "-c:a",
      "aac",
      "-b:a",
      "256k",
      audioOutputPath,
      "-y"
    ]);

    await _ffmpegManager.execute(audioArguments, null);
  }

  await _ffmpegManager.execute([
    "-i",
    videoOutputPath,
    "-i",
    audioOutputPath,
    "-map",
    "0:v",
    "-map",
    "1:a",
    "-c",
    "copy",
    mergeOutputPath,
    "-y"
  ], null);

  return RenderedData(mergeOutputPath, totalDuration);
}

Future<RenderedData> applyMusics(
    RenderedData mergedClip, List<MusicData> musics) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/result.mp4";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  int inputFileCount = 0;

  inputArguments.addAll(["-i", mergedClip.absolutePath]);
  inputFileCount++;

  if (musics.isEmpty) {
    inputArguments.addAll([
      "-f",
      "lavfi",
      "-t",
      mergedClip.duration.toString(),
      "-i",
      "anullsrc=channel_layout=stereo:sample_rate=44100"
    ]);

    filterStrings.add("[$inputFileCount:a]volume=0[bgm];");
    inputFileCount++;
  } else if (musics.length == 1) {
    final MusicData musicData = musics[0];
    final double duration = musicData.duration;

    inputArguments.addAll(["-i", musicData.absolutePath!]);
    filterStrings.add(
        "[$inputFileCount:a]volume=${musicData.volume}[volume_applied_0];[volume_applied_0]afade=t=out:st=${max(duration - _fadeDuration, 0)}:d=$_fadeDuration[faded0];[faded0]atrim=0:$duration[bgm];");
    inputFileCount++;
  } //
  else {
    String mergeBgmTargets = "";
    for (int i = 0; i < musics.length; i++) {
      final MusicData musicData = musics[i];
      final double duration = musicData.duration;

      inputArguments.addAll(["-i", musicData.absolutePath!]);
      filterStrings.add(
          "[$inputFileCount:a]volume=${musicData.volume}[volume_applied_$i];[volume_applied_$i]afade=t=out:st=${max(duration - _fadeDuration, 0)}:d=$_fadeDuration[faded$i];[faded$i]atrim=0:$duration[aud$inputFileCount];");
      mergeBgmTargets += "[aud$inputFileCount]";
      inputFileCount++;
    }
    filterStrings.add(
        "${mergeBgmTargets}concat=n=${musics.length}:v=0:a=1[bgm];");
  }

  filterStrings.addAll([
    "[0:a]volume=0.8[merge_audio];[merge_audio][bgm]amix=inputs=2:dropout_transition=99999,volume=2[merged];[merged]atrim=0:${mergedClip.duration}[trimed];[trimed]afade=t=out:st=${max(mergedClip.duration - _fadeDuration, 0)}:d=$_fadeDuration[out]"
  ]);

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([
    "-map",
    "0:v",
    "-map",
    "[out]",
    "-c:v",
    "copy",
    "-c:a",
    "aac",
    "-b:a",
    "256k",
    "-shortest",
    outputPath,
    "-y"
  ]);

  await _ffmpegManager.execute(arguments, null);
  return RenderedData(outputPath, mergedClip.duration);
}

Future<String?> extractThumbnail(EditedMedia editedMedia) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/${Uuid().v4()}.jpg";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  final MediaData mediaData = editedMedia.mediaData;
  inputArguments.addAll(["-i", mediaData.scaledPath ?? mediaData.absolutePath]);

  if (mediaData.type == EMediaType.video) {
    inputArguments.addAll(["-ss", editedMedia.startTime.toString()]);
  }

  int cropLeft = max(0, (mediaData.width * editedMedia.cropLeft).floor());
  int cropRight = (mediaData.width * editedMedia.cropRight).floor();
  int cropTop = max(0, (mediaData.height * editedMedia.cropTop).floor());
  int cropBottom = (mediaData.height * editedMedia.cropBottom).floor();

  int cropWidth = cropRight - cropLeft;
  int cropHeight = cropBottom - cropTop;

  filterStrings.add(
      "${_getTransposeFilter(mediaData.orientation)}crop=$cropWidth:$cropHeight:$cropLeft:$cropTop,scale=${(_scaledVideoWidth / 2).floor()}:${(_scaledVideoHeight / 2).floor()},setdar=dar=${_scaledVideoWidth / _scaledVideoHeight}");

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll(["-vframes", "1", outputPath, "-y"]);

  await _ffmpegManager.execute(arguments, null);
  return outputPath;
}

Future<MediaData> scaleImageMedia(MediaData mediaData) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/${Uuid().v4()}.jpg";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  if (mediaData.type == EMediaType.video) return mediaData;

  const int scaleTargetSize = 1440;
  double imageScaleFactor = (scaleTargetSize * 1.0) / min(mediaData.width, mediaData.height);

  if (imageScaleFactor >= 1) return mediaData;
  inputArguments.addAll(["-i", mediaData.absolutePath]);

  int scaledWidth = _getEvenNumber((mediaData.width * imageScaleFactor).floor());
  int scaledHeight = _getEvenNumber((mediaData.height * imageScaleFactor).floor());

  filterStrings.add(
      "${_getTransposeFilter(mediaData.orientation)}scale=$scaledWidth:$scaledHeight,setdar=dar=${scaledWidth / scaledHeight}");

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([outputPath, "-y"]);

  await _ffmpegManager.execute(arguments, null);

  final MediaData resultData = MediaData(mediaData.absolutePath, mediaData.type, scaledWidth, scaledHeight, 0, mediaData.duration, mediaData.createDate, mediaData.gpsString, mediaData.mlkitDetected);
  resultData.scaledPath = outputPath;

  return resultData;
}

int getFramerate() {
  return _framerate;
}

double normalizeTime(double duration) {
  duration -= duration % _minDurationFactor;
  return (duration * 1000).floor() / 1000.0;
}
