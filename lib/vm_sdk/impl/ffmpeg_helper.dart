import 'dart:io';
import 'package:ffmpeg_kit_flutter_full_gpl/statistics.dart';

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
const int _fadeDuration = 3;

class RenderedData {
  String absolutePath;
  double duration;

  RenderedData(this.absolutePath, this.duration);
}

final FFMpegManager _ffmpegManager = FFMpegManager();

void setRatio(ERatio ratio) {
  _ratio = ratio;
  _resolution = Resolution.fromRatio(ratio);

  _scaledVideoWidth = (_resolution.width * _scaleFactor).floor();
  _scaledVideoHeight = (_resolution.height * _scaleFactor).floor();

  _scaledVideoWidth -= (_scaledVideoWidth % 2);
  _scaledVideoHeight -= (_scaledVideoHeight % 2);
}

Future<RenderedData?> clipRender(
    EditedMedia editedMedia,
    int clipIdx,
    TransitionData? prevTransition,
    TransitionData? nextTransition,
    Function(Statistics)? ffmpegCallback) async {
  final MediaData mediaData = editedMedia.mediaData;
  final FrameData? frame = editedMedia.frame;
  final StickerData? sticker = editedMedia.sticker;
  final TextExportData? exportedText = editedMedia.exportedText;

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

  filterStrings.add(
      "[0:v]${trimFilter}scale=${(editedMedia.mediaData.width * editedMedia.zoomX).floor()}:${(editedMedia.mediaData.height * editedMedia.zoomY).floor()},crop=${_resolution.width}:${_resolution.height}:${editedMedia.translateX}:${editedMedia.translateY},setdar=dar=${_resolution.width / _resolution.height}[vid];");
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

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${_resolution.width}:${_resolution.height},setdar=dar=${_resolution.width / _resolution.height}$frameMapVariable;");
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

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS$stickerMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${stickerMapVariable}overlay=${sticker.x}:${sticker.y}$stickerMergedMapVariable;");

    videoOutputMapVariable = stickerMergedMapVariable;
  }

  ///////////////
  // ADD TITLE //
  ///////////////

  if (exportedText != null) {
    String textMapVariable = "[text]";
    String textMergedMapVariable = "[text_merged]";

    inputArguments.addAll([
      "-framerate",
      exportedText.frameRate.toString(),
      "-i",
      "${exportedText.allSequencesPath}/%d.png"
    ]);

    filterStrings.add(
        "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${(exportedText.width * exportedText.scale).floor()}:${(exportedText.height * exportedText.scale).floor()}$textMapVariable;");
    filterStrings.add(
        "$videoOutputMapVariable${textMapVariable}overlay=${exportedText.x}:${exportedText.y}$textMergedMapVariable;");

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

    inputArguments.addAll(
        ["-c:v", "libvpx-vp9", "-i", "$appDirPath/${fileInfo.filename}"]);
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
      "$appDirPath/${fileInfo.filename}"
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
        "${audioMergeTargets}amix=inputs=${mergedClipList.length}:dropout_transition=99999,volume=${mergedClipList.length}[merged];[merged]afade=t=out:st=${(totalDuration - _fadeDuration)}:d=$_fadeDuration[out]";
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

  inputArguments.addAll(["-i", mergedClip.absolutePath]);
  inputFileCount++;

  if (musics.length == 1) {
    final MusicData musicData = musics[0];
    final double duration = musicData.duration;

    inputArguments.addAll(["-i", musicData.absolutePath!]);
    filterStrings.add(
        "[$inputFileCount:a]afade=t=out:st=${(duration - _fadeDuration)}:d=$_fadeDuration[faded0];[faded0]atrim=0:$duration[bgm];[bgm]volume=0.5[bgm_volume_applied];");
    inputFileCount++;
  } //
  else {
    String mergeBgmTargets = "";
    for (int i = 0; i < musics.length; i++) {
      final MusicData musicData = musics[i];
      final double duration = musicData.duration;

      inputArguments.addAll(["-i", musicData.absolutePath!]);
      filterStrings.add(
          "[$inputFileCount:a]afade=t=out:st=${(duration - _fadeDuration)}:d=$_fadeDuration[faded$i];[faded$i]atrim=0:$duration[aud$inputFileCount];");
      mergeBgmTargets += "[aud$inputFileCount]";
      inputFileCount++;
    }
    filterStrings.add(
        "${mergeBgmTargets}concat=n=${musics.length}:v=0:a=1[bgm];[bgm]volume=0.5[bgm_volume_applied];");
  }

  filterStrings.addAll([
    "[0:a][bgm_volume_applied]amix=inputs=2:dropout_transition=99999,volume=2[merged];[merged]atrim=0:${mergedClip.duration}[trimed];[trimed]afade=t=out:st=${(mergedClip.duration - _fadeDuration)}:d=$_fadeDuration[out]"
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

Future<String?> extractThumbnail(
    EditedMedia editedMedia, int clipIdx) async {

  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/thumbnail_$clipIdx.jpg";

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  final MediaData mediaData = editedMedia.mediaData;
  inputArguments.addAll(["-i", mediaData.absolutePath]);

  if (mediaData.type == EMediaType.video) {
    inputArguments.addAll(["-ss", editedMedia.startTime.toString()]);
  }

  filterStrings.add(
      "scale=${(editedMedia.mediaData.width * editedMedia.zoomX).floor()}:${(editedMedia.mediaData.height * editedMedia.zoomY).floor()},crop=${_resolution.width}:${_resolution.height}:${editedMedia.translateX}:${editedMedia.translateY},scale=$_scaledVideoWidth:$_scaledVideoHeight,setdar=dar=${_scaledVideoWidth / _scaledVideoHeight}");

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([
    "-vframes",
    "1",
    outputPath,
    "-y"
  ]);

  bool isSuccess = await _ffmpegManager.execute(arguments, null);
  if (!isSuccess) return null;

  return outputPath;
}

int getFramerate() {
  return _framerate;
}

double normalizeTime(double duration) {
  duration -= duration % _minDurationFactor;
  return (duration * 1000).floor() / 1000.0;
}
