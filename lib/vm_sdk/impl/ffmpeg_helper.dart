import 'dart:io';
import 'dart:math';
import 'package:ffmpeg_kit_flutter_full_gpl/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';
import 'package:ffmpeg_kit_flutter_full_gpl/stream_information.dart';
import 'package:uuid/uuid.dart';

import '../types/types.dart';
import 'global_helper.dart';
import 'ffmpeg_manager.dart';

enum EImageScaleType {
  zoomIn,
  zoomOut,
  leftToRight,
  rightToLeft,
  topToBottom,
  bottomToTop
}

Resolution _resolution = Resolution(0, 0);
int _scaledVideoWidth = 0;
int _scaledVideoHeight = 0;
int _framerate = 30;
ERatio _ratio = ERatio.ratio11;

double _scaleFactor = 2 / 3.0;
double _minDurationFactor = 1 / _framerate;
const int _fadeDuration = 3;

List<EImageScaleType> _imageScaleType = [];
class RenderedData {
  String absolutePath;
  double duration;

  RenderedData(this.absolutePath, this.duration);
}

final FFMpegManager _ffmpegManager = FFMpegManager();

EImageScaleType _getRandomImageScaleType() {
  if (_imageScaleType.isEmpty) {
    _imageScaleType.addAll(EImageScaleType.values);
  }

  int randIdx = (Random()).nextInt(_imageScaleType.length) % _imageScaleType.length;
  EImageScaleType picked = _imageScaleType[randIdx];

  _imageScaleType.removeAt(randIdx);
  return picked;
}

String _getTransposeFilter(int orientation) {
  switch (orientation) {
    case 90: return "transpose=1,";
    case 180: return "transpose=2,transpose=2,";
    case 270: return "transpose=2,";
    default: return "";
  }
}

void setRatio(ERatio ratio) {
  _ratio = ratio;
  _resolution = Resolution.fromRatio(ratio);

  _scaledVideoWidth = (_resolution.width * _scaleFactor).floor();
  _scaledVideoHeight = (_resolution.height * _scaleFactor).floor();

  _scaledVideoWidth -= (_scaledVideoWidth % 2);
  _scaledVideoHeight -= (_scaledVideoHeight % 2);
}

Future<RenderedData> clipRender(
    EditedMedia editedMedia,
    int clipIdx,
    TransitionData? prevTransition,
    TransitionData? nextTransition,
    Function(Statistics)? ffmpegCallback) async {
  final MediaData mediaData = editedMedia.mediaData;
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
        .addAll(["-framerate", "$_framerate", "-loop", "1", "-t", "$duration"]);
    inputArguments.addAll(["-t", "$duration", "-i", mediaData.absolutePath]);

    audioOutputMapVariable = "1:a";
  } //
  else {
    trimFilter = "trim=$startTime:${startTime + duration},setpts=PTS-STARTPTS,";
    inputArguments
        .addAll(["-r", _framerate.toString(), "-i", mediaData.absolutePath]);

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

  int scaledWidth = max((editedMedia.mediaData.width * editedMedia.zoomX).floor() + 2, _resolution.width);
  int scaledHeight = max((editedMedia.mediaData.height * editedMedia.zoomY).floor() + 2, _resolution.height);

  filterStrings.add(
      "[0:v]$trimFilter${_getTransposeFilter(mediaData.orientation)}scale=$scaledWidth:$scaledHeight,crop=${_resolution.width}:${_resolution.height}:${editedMedia.translateX}:${editedMedia.translateY},setdar=dar=${_resolution.width / _resolution.height}[vid];");
  videoOutputMapVariable = "[vid]";
  inputFileCount++;

  ///////////////////////////
  // IMAGE SCALE ANIMATION //
  ///////////////////////////
  if (mediaData.type == EMediaType.image) {
    const int animationSpeed = 96;
    final int videoWidth = _resolution.width;
    final int videoHeight = _resolution.height;

    String startScaleWidth = "",
        startScaleHeight = "",
        cropPosX = "",
        cropPosY = "";
    int scaleAddVal = 0, cropZoomVal = 0;

    final EImageScaleType type = _getRandomImageScaleType();

    switch (type) {
      case EImageScaleType.zoomIn:
        {
          scaleAddVal = (editedMedia.duration * animationSpeed).floor();
          cropZoomVal = (editedMedia.duration * (animationSpeed / 2)).floor();

          startScaleWidth = "-1";
          startScaleHeight = "${(videoHeight * 3).floor()}+($scaleAddVal*t)";
          cropPosX = "($cropZoomVal*t)";
          cropPosY = "($cropZoomVal*t)";
        }
        break;

      case EImageScaleType.zoomOut:
        {
          scaleAddVal = (editedMedia.duration * animationSpeed).floor();
          cropZoomVal = (editedMedia.duration * (animationSpeed / 2)).floor();

          startScaleWidth = "-1";
          startScaleHeight =
              "${(videoHeight * 3 + scaleAddVal * editedMedia.duration).floor()}-($scaleAddVal*t)";
          cropPosX =
              "(${(cropZoomVal * editedMedia.duration).floor()}-$cropZoomVal*t)";
          cropPosY =
              "(${(cropZoomVal * editedMedia.duration).floor()}-$cropZoomVal*t)";
        }
        break;

      case EImageScaleType.leftToRight:
        {
          cropZoomVal = animationSpeed * 2;

          startScaleWidth = "-1";
          startScaleHeight =
              "${(videoHeight * 3 + (cropZoomVal * 2 * editedMedia.duration)).floor()}";
          cropPosX = "($cropZoomVal*t)";
          cropPosY = "${((cropZoomVal / 2) * editedMedia.duration).floor()}";
        }
        break;

      case EImageScaleType.rightToLeft:
        {
          cropZoomVal = animationSpeed * 2;

          startScaleWidth = "-1";
          startScaleHeight =
              "${(videoHeight * 3 + (cropZoomVal * 2 * editedMedia.duration)).floor()}";
          cropPosX =
              "(${(cropZoomVal * editedMedia.duration).floor()}-$cropZoomVal*t)";
          cropPosY = "${((cropZoomVal / 2) * editedMedia.duration).floor()}";
        }
        break;

      case EImageScaleType.topToBottom:
        {
          cropZoomVal = animationSpeed * 2;

          startScaleWidth = "-1";
          startScaleHeight =
              "${(videoHeight * 3 + (cropZoomVal * 2 * editedMedia.duration)).floor()}";
          cropPosX = "${((cropZoomVal / 2) * editedMedia.duration).floor()}";
          cropPosY = "($cropZoomVal*t)";
        }
        break;

      case EImageScaleType.bottomToTop:
      default:
        {
          cropZoomVal = animationSpeed * 2;

          startScaleWidth = "-1";
          startScaleHeight =
              "${(videoHeight * 3 + (cropZoomVal * 2 * editedMedia.duration)).floor()}";
          cropPosX = "${((cropZoomVal / 2) * editedMedia.duration).floor()}";
          cropPosY =
              "(${(cropZoomVal * editedMedia.duration).floor()}-$cropZoomVal*t)";
        }
        break;
    }

    filterStrings.add(
        "${videoOutputMapVariable}scale=$startScaleWidth:$startScaleHeight:eval=frame,crop=${(videoWidth * 3).floor()}:${(videoHeight * 3).floor()}:$cropPosX:$cropPosY,scale=$videoWidth:$videoHeight[applied_animation];");

    videoOutputMapVariable = "[applied_animation]";
  }

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

    filterStrings.add(
        "[${inputFileCount++}:v]scale=${canvasText.width}:${canvasText.height}$canvasTextScaledMapVariable;");
    filterStrings.add(
        "${canvasTextScaledMapVariable}rotate=$rotate:c=none:ow=rotw($rotate):oh=roth($rotate)$canvasTextRotatedMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${canvasTextRotatedMapVariable}overlay=${canvasText.x}-(((${canvasText.width}*cos($rotateForCal)+${canvasText.height}*sin($rotateForCal))-${canvasText.width})/2):${canvasText.y}-(((${canvasText.width}*sin($rotateForCal)+${canvasText.height}*cos($rotateForCal))-${canvasText.height})/2)$canvasTextMergedMapVariable;");

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

      filterStrings.add(
          "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=$width:$height$textMapVariable;");
      filterStrings.add(
          "${textMapVariable}rotate=$rotate:c=none:ow=rotw($rotate):oh=roth($rotate)$textRotatedMapVariable;");
      filterStrings.add(
          "$videoOutputMapVariable${textRotatedMapVariable}overlay=${editedText.x}-((($width*cos($rotateForCal)+$height*sin($rotateForCal))-$width)/2):${editedText.y}-((($width*sin($rotateForCal)+$height*cos($rotateForCal))-$height)/2)$textMergedMapVariable;");

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

    filterStrings.add("[$inputFileCount:a]volume=0[bgm_volume_applied];");
    inputFileCount++;
  } else if (musics.length == 1) {
    final MusicData musicData = musics[0];
    final double duration = musicData.duration;

    inputArguments.addAll(["-i", musicData.absolutePath!]);
    filterStrings.add(
        "[$inputFileCount:a]afade=t=out:st=${max(duration - _fadeDuration, 0)}:d=$_fadeDuration[faded0];[faded0]atrim=0:$duration[bgm];[bgm]volume=0.5[bgm_volume_applied];");
    inputFileCount++;
  } //
  else {
    String mergeBgmTargets = "";
    for (int i = 0; i < musics.length; i++) {
      final MusicData musicData = musics[i];
      final double duration = musicData.duration;

      inputArguments.addAll(["-i", musicData.absolutePath!]);
      filterStrings.add(
          "[$inputFileCount:a]afade=t=out:st=${max(duration - _fadeDuration, 0)}:d=$_fadeDuration[faded$i];[faded$i]atrim=0:$duration[aud$inputFileCount];");
      mergeBgmTargets += "[aud$inputFileCount]";
      inputFileCount++;
    }
    filterStrings.add(
        "${mergeBgmTargets}concat=n=${musics.length}:v=0:a=1[bgm];[bgm]volume=0.5[bgm_volume_applied];");
  }

  filterStrings.addAll([
    "[0:a]volume=0.8[merge_audio];[merge_audio][bgm_volume_applied]amix=inputs=2:dropout_transition=99999,volume=2[merged];[merged]atrim=0:${mergedClip.duration}[trimed];[trimed]afade=t=out:st=${max(mergedClip.duration - _fadeDuration, 0)}:d=$_fadeDuration[out]"
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
  inputArguments.addAll(["-i", mediaData.absolutePath]);

  if (mediaData.type == EMediaType.video) {
    inputArguments.addAll(["-ss", editedMedia.startTime.toString()]);
  }

  filterStrings.add(
      "${_getTransposeFilter(mediaData.orientation)}scale=${(editedMedia.mediaData.width * editedMedia.zoomX).floor()}:${(editedMedia.mediaData.height * editedMedia.zoomY).floor()},crop=${_resolution.width}:${_resolution.height}:${editedMedia.translateX}:${editedMedia.translateY},scale=${(_scaledVideoWidth / 2).floor()}:${(_scaledVideoHeight / 2).floor()},setdar=dar=${_scaledVideoWidth / _scaledVideoHeight}");

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

Future<MediaData> scaleImageMedia( MediaData mediaData) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/${Uuid().v4()}.jpg";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  if (mediaData.type == EMediaType.video) return mediaData;

  int scaledTargetSize = 1920;
  double imageScaleFactor = 1.0;

  if (mediaData.width <= scaledTargetSize && mediaData.height <= scaledTargetSize) return mediaData;
  inputArguments.addAll(["-i", mediaData.absolutePath]);

  if (mediaData.width >= mediaData.height) {
    imageScaleFactor = scaledTargetSize / mediaData.width;
  }
  else {
    imageScaleFactor = scaledTargetSize / mediaData.height;
  }

  int scaledWidth = (mediaData.width * imageScaleFactor).floor();
  int scaledHeight = (mediaData.height * imageScaleFactor).floor();

  scaledWidth -= scaledWidth % 2;
  scaledHeight -= scaledHeight % 2;

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
  return MediaData(outputPath, mediaData.type, scaledWidth, scaledHeight, 0, mediaData.duration, mediaData.createDate, mediaData.gpsString, mediaData.mlkitDetected);
}

int getFramerate() {
  return _framerate;
}

double normalizeTime(double duration) {
  duration -= duration % _minDurationFactor;
  return (duration * 1000).floor() / 1000.0;
}
