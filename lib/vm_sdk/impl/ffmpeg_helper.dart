import 'dart:io';
import '../types/types.dart';
import 'global_helper.dart';
import 'ffmpeg_manager.dart';
import 'package:flutter_ffmpeg/statistics.dart' show Statistics;

int _videoWidth = 1280;
int _videoHeight = 720;
int _framerate = 30;
ERatio _ratio = ERatio.ratio11;

double _scaleFactor = 2 / 3.0;
double _minDurationFactor = 1 / _framerate;

class CropData {
  int scaledWidth = 0;
  int scaledHeight = 0;
  int cropPosX = 0;
  int cropPosY = 0;

  CropData(this.scaledWidth, this.scaledHeight, this.cropPosX, this.cropPosY);
}

class RenderedData {
  String absolutePath;
  double duration;

  RenderedData(this.absolutePath, this.duration);
}

final FFMpegManager _ffmpegManager = FFMpegManager();

void setRatio(ERatio ratio) {
  _ratio = ratio;
  switch (ratio) {
    case ERatio.ratio169:
      _videoWidth = 1920;
      _videoHeight = 1080;
      break;

    case ERatio.ratio916:
      _videoWidth = 1080;
      _videoHeight = 1920;
      break;

    case ERatio.ratio11:
    default:
      _videoWidth = 1080;
      _videoHeight = 1080;
      break;
  }

  _videoWidth = (_videoWidth * _scaleFactor).floor();
  _videoHeight = (_videoHeight * _scaleFactor).floor();
}

CropData generateCropData(int width, int height) {
  int scaledWidth = _videoWidth;
  int scaledHeight = _videoHeight;
  int cropPosX = 0;
  int cropPosY = 0;

  if (width > height) {
    scaledWidth = (width * (_videoHeight / height)).floor();
    if (scaledWidth % 2 == 1) scaledWidth -= 1;
    cropPosX = ((scaledWidth - _videoWidth) / 2.0).floor();
  } else {
    scaledHeight = (height * (_videoWidth / width)).floor();
    if (scaledHeight % 2 == 1) scaledHeight -= 1;
    cropPosY = ((scaledHeight - _videoHeight) / 2.0).floor();
  }

  return CropData(scaledWidth, scaledHeight, cropPosX, cropPosY);
}

Future<RenderedData?> clipRender(
    AutoEditMedia autoEditMedia,
    int clipIdx,
    FrameData? frame,
    StickerData? sticker,
    TransitionData? prevTransition,
    TransitionData? nextTransition,
    ExportedTextPNGSequenceData? exportedText,
    Function(Statistics)? ffmpegCallback) async {
  final MediaData mediaData = autoEditMedia.mediaData;
  double duration =
      normalizeTime(autoEditMedia.duration + autoEditMedia.xfadeDuration);
  double startTime = normalizeTime(autoEditMedia.startTime);

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

    filterStrings.add(
        "[0:a]atrim=$startTime:${startTime + duration},asetpts=PTS-STARTPTS[aud];[aud][1:a]amix=inputs=2[aud_mixed];[aud_mixed]atrim=0:$duration,asetpts=PTS-STARTPTS[aud_trim];");
    audioOutputMapVariable = "[aud_trim]";
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

  final CropData cropData = generateCropData(mediaData.width, mediaData.height);
  filterStrings.add(
      "[0:v]${trimFilter}scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$_videoWidth:$_videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${_videoWidth / _videoHeight}[vid];");
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
      "$appDirPath/${fileInfo.filename}"
    ]);

    final CropData cropData = generateCropData(fileInfo.width, fileInfo.height);
    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$_videoWidth:$_videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${_videoWidth / _videoHeight}$frameMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${frameMapVariable}overlay$frameMergedMapVariable;");

    videoOutputMapVariable = frameMergedMapVariable;
  }

  /////////////////
  // ADD STICKER //
  /////////////////

  if (sticker != null) {
    ResourceFileInfo fileInfo = sticker.fileinfo!;

    final int loopCount = (duration / fileInfo.duration).floor();
    const String stickerMapVariable = "[sticker]";
    const String stickerMergedMapVariable = "[sticker_merged]";

    inputArguments.addAll([
      "-stream_loop",
      loopCount.toString(),
      "-c:v",
      "libvpx-vp9",
      "-i",
      "$appDirPath/${fileInfo.filename}"
    ]);

    final int scaledWidth = (fileInfo.width * _scaleFactor).floor();
    final int scaledHeight = (fileInfo.height * _scaleFactor).floor();

    final int x = _videoWidth - scaledWidth;
    final int y = _videoHeight - scaledHeight;

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=$scaledWidth:$scaledHeight,setdar=dar=${scaledWidth / scaledHeight}$stickerMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${stickerMapVariable}overlay=$x:$y$stickerMergedMapVariable;");

    videoOutputMapVariable = stickerMergedMapVariable;
  }

  ///////////////
  // ADD TITLE //
  ///////////////

  if (exportedText != null) {
    final int maxTextWidth = (_videoWidth * 0.9).floor();
    if (exportedText.width > maxTextWidth) {
      final double textScaleFactor = maxTextWidth / exportedText.width;

      exportedText.width = (exportedText.width * textScaleFactor).floor();
      exportedText.height = (exportedText.height * textScaleFactor).floor();
    }

    final double startPosY = (_videoHeight / 2) - (exportedText.height / 2);

    String textMapVariable = "[text]";
    String textMergedMapVariable = "[text_merged]";

    double currentPosX = (_videoWidth / 2) - (exportedText.width / 2);

    inputArguments.addAll([
      "-framerate",
      exportedText.frameRate.toString(),
      "-i",
      "${exportedText.folderPath}/%d.png"
    ]);

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${exportedText.width}:${exportedText.height}$textMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${textMapVariable}overlay=$currentPosX:$startPosY$textMergedMapVariable;");

    videoOutputMapVariable = textMergedMapVariable;
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

    final CropData cropData = generateCropData(fileInfo.width, fileInfo.height);

    inputArguments.addAll(
        ["-c:v", "libvpx-vp9", "-i", "$appDirPath/${fileInfo.filename}"]);
    filterStrings.add(
        "[${inputFileCount++}:v]trim=${fileInfo.transitionPoint}:${fileInfo.duration},setpts=PTS-STARTPTS,scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$_videoWidth:$_videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$transitionMapVariable;");
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

    final CropData cropData = generateCropData(fileInfo.width, fileInfo.height);

    inputArguments.addAll([
      "-c:v",
      "libvpx-vp9",
      "-itsoffset",
      (duration - fileInfo.transitionPoint).toString(),
      "-i",
      "$appDirPath/${fileInfo.filename}"
    ]);
    filterStrings.add(
        "[${inputFileCount++}:v]scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$_videoWidth:$_videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$transitionMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${transitionMapVariable}overlay=enable='between(t\\,${duration - fileInfo.transitionPoint},$duration)'$transitionMergedMapVariable;");
    videoOutputMapVariable = transitionMergedMapVariable;
  }

  filterStrings.add(
      "${videoOutputMapVariable}trim=0:$duration,setpts=PTS-STARTPTS[out_vid];");
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

  bool isSuccess = await _ffmpegManager.execute(arguments, ffmpegCallback);
  if (!isSuccess) return null;

  return RenderedData(outputPath, duration);
}

Future<RenderedData?> applyXFadeTransitions(
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

  bool isSuccess = await _ffmpegManager.execute([
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
  if (!isSuccess) return null;

  return RenderedData(outputPath, duration);
}

Future<RenderedData?> mergeVideoClip(List<RenderedData> clipList) async {
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
        bool isSuccess = await _ffmpegManager.execute([
          "-i",
          currentList[0].absolutePath,
          "-map",
          "0:v",
          "-c:v",
          "copy",
          videoOutputPath,
          "-y"
        ], null);

        isSuccess = isSuccess &&
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
        if (!isSuccess) return null;
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

        bool isSuccess = await _ffmpegManager.execute([
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

        isSuccess =
            isSuccess && await _ffmpegManager.execute(audioArguments, null);
        if (!isSuccess) return null;
      }

      bool isSuccess = await _ffmpegManager.execute([
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
      if (!isSuccess) return null;

      mergedClipList.add(RenderedData(mergeOutputPath, mergedDuration));
      currentList = [];
    }
  }

  final String videoOutputPath = "$appDirPath/allclip_merged_video.mp4";
  final String audioOutputPath = "$appDirPath/allclip_merged_audio.m4a";
  final String mergeOutputPath = "$appDirPath/allclip_merged_all.mp4";

  if (mergedClipList.length == 1) {
    bool isSuccess = await _ffmpegManager.execute([
      "-i",
      mergedClipList[0].absolutePath,
      "-map",
      "0:v",
      "-c:v",
      "copy",
      videoOutputPath,
      "-y"
    ], null);

    isSuccess = isSuccess &&
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
    if (!isSuccess) return null;
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

    bool isSuccess = await _ffmpegManager.execute([
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
        "${audioMergeTargets}amix=inputs=${mergedClipList.length}:dropout_transition=99999,volume=${mergedClipList.length}[out]";
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

    isSuccess = isSuccess && await _ffmpegManager.execute(audioArguments, null);
    if (!isSuccess) return null;
  }

  bool isSuccess = await _ffmpegManager.execute([
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
  if (!isSuccess) return null;

  return RenderedData(mergeOutputPath, totalDuration);
}

Future<RenderedData?> applyMusics(
    RenderedData mergedClip, List<MusicData> musics) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/result.mp4";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  int inputFileCount = 0;
  const int fadeDuration = 3;

  inputArguments.addAll(["-i", mergedClip.absolutePath]);
  inputFileCount++;

  if (musics.length == 1) {
    final MusicData musicData = musics[0];
    final double duration = musicData.duration;

    inputArguments.addAll(["-i", "$appDirPath/${musicData.filename}"]);
    filterStrings.add(
        "[$inputFileCount:a]afade=t=out:st=${(duration - fadeDuration)}:d=$fadeDuration[faded0];[faded0]atrim=0:$duration[bgm];");
    inputFileCount++;
  } //
  else {
    String mergeBgmTargets = "";
    for (int i = 0; i < musics.length; i++) {
      final MusicData musicData = musics[i];
      final double duration = musicData.duration;

      inputArguments.addAll(["-i", "$appDirPath/${musicData.filename}"]);
      filterStrings.add(
          "[$inputFileCount:a]afade=t=out:st=${(duration - fadeDuration)}:d=$fadeDuration[faded$i];[faded$i]atrim=0:$duration[aud$inputFileCount];");
      mergeBgmTargets += "[aud$inputFileCount]";
      inputFileCount++;
    }
    filterStrings.add(
        "${mergeBgmTargets}concat=n=${musics.length}:v=0:a=1[bgm];[bgm]volume=0.5[bgm_volume_applied];");
  }

  filterStrings.addAll([
    "[0:a][bgm_volume_applied]amix=inputs=2:dropout_transition=99999,volume=2[merged];[merged]atrim=0:${mergedClip.duration}[out]"
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

  bool isSuccess = await _ffmpegManager.execute(arguments, null);
  if (!isSuccess) return null;

  return RenderedData(outputPath, mergedClip.duration);
}

int getFramerate() {
  return _framerate;
}

double normalizeTime(double duration) {
  duration -= duration % _minDurationFactor;
  return (duration * 1000).floor() / 1000.0;
}
