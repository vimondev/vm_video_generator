import '../types/types.dart';
import 'global_helper.dart';

int videoWidth = 1280;
int videoHeight = 720;
int framerate = 30;

class GenerateArgumentResponse {
  List<String> arguments;
  String outputPath;
  int? totalFrame;

  GenerateArgumentResponse(this.arguments, this.outputPath, this.totalFrame);
}

class CropData {
  int scaledWidth = 0;
  int scaledHeight = 0;
  int cropPosX = 0;
  int cropPosY = 0;

  CropData(this.scaledWidth, this.scaledHeight, this.cropPosX, this.cropPosY);
}

CropData generateCropData(int width, int height) {
  int scaledWidth = videoWidth;
  int scaledHeight = videoHeight;
  int cropPosX = 0;
  int cropPosY = 0;

  if (width > height) {
    scaledWidth = (width * (videoHeight / height)).floor();
    if (scaledWidth % 2 == 1) scaledWidth -= 1;
    cropPosX = ((scaledWidth - videoWidth) / 2.0).floor();
  } else {
    scaledHeight = (height * (videoWidth / width)).floor();
    if (scaledHeight % 2 == 1) scaledHeight -= 1;
    cropPosY = ((scaledHeight - videoHeight) / 2.0).floor();
  }

  return CropData(scaledWidth, scaledHeight, cropPosX, cropPosY);
}

Future<GenerateArgumentResponse> generateVideoRenderArgument(
    AutoEditedData autoEditedData,
    ExportedTitlePNGSequenceData exportedTitle) async {
  final List<AutoEditMedia> autoEditMediaList =
      autoEditedData.autoEditMediaList;
  final Map<String, TransitionData> transitionMap =
      autoEditedData.transitionMap;
  final Map<String, StickerData> stickerMap = autoEditedData.stickerMap;

  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/video_out.mp4";
  final Map<int, double> calculatedDurationMap = {};
  double totalDuration = 0;

  int inputFileCount = 0;
  final Map<int, String?> videoMapVariables = <int, String?>{}; // ex) [vid0]
  final List<String> inputArguments = <String>[]; // -i arguments
  final List<String> filterStrings = <String>[]; // -filter_complex strings

  /////////////////////////
  // INPUT IMAGE & VIDEO //
  /////////////////////////
  for (int i = 0; i < autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditMediaList[i];
    final MediaData mediaData = autoEditMedia.mediaData;
    final TransitionData? transition =
        transitionMap[autoEditMedia.transitionKey];
    double calculatedDuration = autoEditMedia.duration;

    // if (transition != null && transition.type == ETransitionType.xfade) {
    //   calculatedDuration += 1;
    // }

    String trimStr = "";
    if (mediaData.type == EMediaType.image) {
      inputArguments.addAll([
        "-framerate",
        "$framerate",
        "-loop",
        "1",
        "-t",
        "$calculatedDuration"
      ]);
    } //
    else {
      trimStr =
          "fps=$framerate,trim=${autoEditMedia.startTime}:${autoEditMedia.startTime + calculatedDuration},setpts=PTS-STARTPTS,";
    }
    inputArguments.addAll(["-i", mediaData.absolutePath]);
    inputFileCount++;

    final CropData cropData =
        generateCropData(mediaData.width, mediaData.height);

    filterStrings.add(
        "[$i:v]${trimStr}scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${videoWidth / videoHeight}[vid$i];");
    videoMapVariables[i] = "[vid$i]";
    calculatedDurationMap[i] = calculatedDuration;
    totalDuration += autoEditMedia.duration;
  }

  ////////////////
  // ADD STICKER//
  ////////////////
  int stickerCount = 0;

  for (int i = 0; i < autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditMediaList[i];
    final StickerData? sticker = stickerMap[autoEditMedia.stickerKey];

    if (sticker != null) {
      final double calculatedDuration = calculatedDurationMap[i]!;

      final String currentVideoMapVariable = videoMapVariables[i]!;

      final int loopCount = (calculatedDuration / sticker.duration).floor();
      final String stickerMapVariable = "[sticker${stickerCount++}]";
      final String stickerMergedMapVariable = "[sticker_merged_$i]";

      inputArguments.addAll([
        "-stream_loop",
        loopCount.toString(),
        "-c:v",
        "libvpx-vp9",
        "-i",
        "$appDirPath/${sticker.filename}"
      ]);

      if (sticker.type == EStickerType.background) {
        final CropData cropData =
            generateCropData(sticker.width, sticker.height);
        filterStrings.add(
            "[${inputFileCount++}:v]fps=$framerate,trim=0:$calculatedDuration,setpts=PTS-STARTPTS,scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${videoWidth / videoHeight}$stickerMapVariable;");
        filterStrings.add(
            "$currentVideoMapVariable${stickerMapVariable}overlay$stickerMergedMapVariable;");
      } //
      else {
        final int x = videoWidth - sticker.width - 100;
        final int y = videoHeight - sticker.height - 100;

        filterStrings.add(
            "[${inputFileCount++}:v]fps=$framerate,trim=0:$calculatedDuration,setpts=PTS-STARTPTS,setdar=dar=${sticker.width / sticker.height}$stickerMapVariable;");
        filterStrings.add(
            "$currentVideoMapVariable${stickerMapVariable}overlay=$x:$y$stickerMergedMapVariable;");
      }

      videoMapVariables[i] = stickerMergedMapVariable;
    }
  }
  // ADD TITLE

  exportedTitle.width = (exportedTitle.width * 1.2).floor();
  exportedTitle.height = (exportedTitle.height * 1.2).floor();

  final double startPosY = (videoHeight / 2) - (exportedTitle.height / 2);

  String titleMapVariable = "[title0]";
  String titleMergedMapVariable = "[title_merged_0]";

  double currentPosX = (videoWidth / 2) - (exportedTitle.width / 2);

  inputArguments.addAll([
    "-framerate",
    exportedTitle.frameRate.toString(),
    "-i",
    "${exportedTitle.folderPath}/%d.png"
  ]);

  filterStrings.add(
      "[${inputFileCount++}:v]trim=0:${autoEditMediaList[0].duration},setpts=PTS-STARTPTS,scale=${exportedTitle.width}:${exportedTitle.height}$titleMapVariable;");
  filterStrings.add(
      "${videoMapVariables[0]!}${titleMapVariable}overlay=$currentPosX:$startPosY$titleMergedMapVariable;");

  videoMapVariables[0] = titleMergedMapVariable;

  // ADD XFADE TRANSITION
  // TO DO: Add some condition

  /////////////////////////////////////////
  // generate video merge & scale command//
  /////////////////////////////////////////
  String mergeTargetStr = "";
  int mergeCount = 0;
  for (final String? videoOutputStr in videoMapVariables.values) {
    if (videoOutputStr != null) {
      mergeTargetStr += videoOutputStr;
      mergeCount++;
    }
  }

  String currentOutputMapVariable = "[merged]";
  filterStrings.add("${mergeTargetStr}concat=n=$mergeCount[merged];");

  ////////////////////////////
  // ADD OVERLAY TRANSITION //
  ////////////////////////////
  double currentDuration = 0;
  int transitionCount = 0;

  for (int i = 0; i < autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditMediaList[i];
    final double duration = autoEditMedia.duration;
    currentDuration += duration;

    final TransitionData? transition =
        transitionMap[autoEditMedia.transitionKey];

    if (transition != null && transition.type == ETransitionType.overlay) {
      String transitionMapVariable = "[transition${transitionCount++}]";
      String transitionMergedMapVariable = "[transition_merged_$i]";

      final CropData cropData =
          generateCropData(transition.width!, transition.height!);

      inputArguments.addAll([
        "-c:v",
        "libvpx-vp9",
        "-itsoffset",
        (currentDuration - transition.transitionPoint!).toString(),
        "-i",
        "$appDirPath/${transition.filename!}"
      ]);
      filterStrings.add(
          "[${inputFileCount++}:v]scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$transitionMapVariable;");
      filterStrings.add(
          "$currentOutputMapVariable${transitionMapVariable}overlay$transitionMergedMapVariable;");

      currentOutputMapVariable = transitionMergedMapVariable;
    }
  }

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
    currentOutputMapVariable,
    "-c:v",
    "libx264",
    "-preset",
    "superfast",
    "-maxrate",
    "5M",
    "-bufsize",
    "5M",
    "-pix_fmt",
    "yuv420p",
    outputPath,
    "-y"
  ]);

  return GenerateArgumentResponse(
      arguments, outputPath, (totalDuration * framerate).floor());
}

Future<GenerateArgumentResponse> generateAudioRenderArgument(
    AutoEditedData autoEditedData) async {
  final List<MusicData> musicList = autoEditedData.musicList;
  final List<AutoEditMedia> autoEditMediaList =
      autoEditedData.autoEditMediaList;

  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  final String outputPath = "$appDirPath/audio_out.m4a";
  double totalDuration = 0;

  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  int inputFileCount = 0;
  double currentDuration = 0;

  String? mergeClipSoundTargets;
  int mergeClipSoundCount = 0;
  String? clipSoundMergedOutput;
  for (int i = 0; i < autoEditMediaList.length; i++) {
    final AutoEditMedia autoEditMedia = autoEditMediaList[i];
    final MediaData mediaData = autoEditMedia.mediaData;
    final double duration = autoEditMedia.duration;

    // if (mediaData.type == EMediaType.video) {
    //   inputArguments.addAll(["-i", mediaData.absolutePath]);
    //   filterStrings.add(
    //       "[$inputFileCount:a]atrim=${autoEditMedia.startTime}:${autoEditMedia.startTime + autoEditMedia.duration}[trim$inputFileCount];[trim$inputFileCount]adelay=${(currentDuration * 1000).floor()}[aud$inputFileCount];");

    //   mergeClipSoundTargets ??= "";
    //   mergeClipSoundTargets += "[aud$inputFileCount]";
    //   mergeClipSoundCount++;

    //   inputFileCount++;
    // }

    currentDuration += duration;
    totalDuration += duration;
  }
  if (mergeClipSoundTargets != null) {
    filterStrings.add(
        "${mergeClipSoundTargets}amix=inputs=$mergeClipSoundCount[clip_mixed];[clip_mixed]atrim=0:$totalDuration[clipsound];");
    clipSoundMergedOutput = "[clipsound]";
  }

  const int fadeDuration = 3;
  if (musicList.length == 1) {
    final MusicData musicData = musicList[0];
    final double duration = musicData.duration;

    inputArguments.addAll(["-i", "$appDirPath/${musicData.filename}"]);
    filterStrings.add(
        "[$inputFileCount:a]afade=t=out:st=${(duration - fadeDuration)}:d=$fadeDuration[faded0];[faded0]atrim=0:$duration[bgm];");
    inputFileCount++;
  } //
  else {
    String mergeBgmTargets = "";
    for (int i = 0; i < musicList.length; i++) {
      final MusicData musicData = musicList[i];
      final double duration = musicData.duration;

      inputArguments.addAll(["-i", "$appDirPath/${musicData.filename}"]);
      filterStrings.add(
          "[$inputFileCount:a]afade=t=out:st=${(duration - fadeDuration)}:d=$fadeDuration[faded$i];[faded$i]atrim=0:$duration[aud$inputFileCount];");
      mergeBgmTargets += "[aud$inputFileCount]";
      inputFileCount++;
    }
    filterStrings
        .add("${mergeBgmTargets}concat=n=${musicList.length}:v=0:a=1[bgm];");
  }

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  if (clipSoundMergedOutput != null) {
    filterComplexStr +=
        "$clipSoundMergedOutput[bgm]amix=inputs=2[all_mixed];[all_mixed]atrim=0:$totalDuration[out]";
  } //
  else {
    filterComplexStr += "[bgm]atrim=0:$totalDuration[out]";
  }

  String inputArgumentsStr = "";
  for (final String inputStr in inputArguments) {
    inputArgumentsStr += inputStr + ',';
  }
  print(inputArgumentsStr);
  print(filterComplexStr);

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll(
      ["-map", "[out]", "-c:a", "aac", "-b:a", "256k", outputPath, "-y"]);

  return GenerateArgumentResponse(arguments, outputPath, null);
}

// Future<GenerateArgumentResponse> generateVideoRenderArgument(
//     TemplateData templateData, List<MediaData> list) async {
//   final List<String> arguments = <String>[];
//   final String appDirPath = await getAppDirectoryPath();
//   String outputPath = "$appDirPath/video_out.mp4";
//   double totalDuration = 0;

//   Map<int, String?> videoMapVariables = <int, String?>{}; // ex) [vid0]
//   Map<int, double> durationMap = <int, double>{}; // scene duration
//   Map<int, double> xfadeDurationMap = <int, double>{};
//   Map<int, StickerData> stickerMap = <int, StickerData>{};
//   Map<int, TransitionData> transitionMap = <int, TransitionData>{};

//   int inputFileCount = 0;
//   final List<String> inputArguments = <String>[]; // -i arguments
//   final List<String> filterStrings = <String>[]; // -filter_complex strings

//   // INPUT IMAGE & VIDEO
//   for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
//     final SceneData sceneData = templateData.scenes[i];
//     final MediaData mediaData = list[i];
//     double xfadeDuration = 0;

//     if (sceneData.stickerKey != null &&
//         templateData.stickerDatas.containsKey(sceneData.stickerKey)) {
//       stickerMap[i] = templateData.stickerDatas[sceneData.stickerKey]!;
//     }
//     if (sceneData.transitionKey != null &&
//         templateData.transitionDatas.containsKey(sceneData.transitionKey)) {
//       final TransitionData transition =
//           templateData.transitionDatas[sceneData.transitionKey]!;
//       transitionMap[i] = transition;

//       if (transition.type == ETransitionType.xfade) {
//         xfadeDuration = 1;
//       }
//     }

//     String trimStr = "";
//     if (mediaData.type == EMediaType.image) {
//       inputArguments.addAll([
//         "-framerate",
//         "$framerate",
//         "-loop",
//         "1",
//         "-t",
//         "${(sceneData.duration + xfadeDuration)}"
//       ]);
//     } else {
//       trimStr =
//           "fps=$framerate,trim=0:${(sceneData.duration + xfadeDuration)},setpts=PTS-STARTPTS,";
//     }
//     inputArguments.addAll(["-i", mediaData.absolutePath]);
//     inputFileCount++;

//     final CropData cropData =
//         generateCropData(mediaData.width, mediaData.height);

//     filterStrings.add(
//         "[$i:v]${trimStr}scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${videoWidth / videoHeight}[vid$i];");
//     videoMapVariables[i] = "[vid$i]";

//     totalDuration += sceneData.duration;
//     durationMap[i] = sceneData.duration;
//     xfadeDurationMap[i] = xfadeDuration;
//   }

//   // ADD FILTER (i => scene index)
//   int stickerCount = 0;

//   for (int i = 0; i < videoMapVariables.length; i++) {
//     if (stickerMap.containsKey(i)) {
//       final double duration = durationMap[i]!;
//       final double additionalDuration = xfadeDurationMap[i]!;
//       final double totalSceneDuration = duration + additionalDuration;

//       final String currentVideoMapVariable = videoMapVariables[i]!;
//       StickerData sticker = stickerMap[i]!;

//       final int loopCount = (totalSceneDuration / sticker.duration).floor();
//       String stickerMapVariable = "[sticker${stickerCount++}]";
//       String stickerMergedMapVariable = "[sticker_merged_$i]";

//       final CropData cropData = generateCropData(sticker.width, sticker.height);

//       inputArguments.addAll([
//         "-stream_loop",
//         loopCount.toString(),
//         "-c:v",
//         "libvpx-vp9",
//         "-i",
//         "$appDirPath/${sticker.filename}"
//       ]);
//       filterStrings.add(
//           "[${inputFileCount++}:v]trim=0:$totalSceneDuration,setpts=PTS-STARTPTS,scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$stickerMapVariable;");
//       filterStrings.add(
//           "$currentVideoMapVariable${stickerMapVariable}overlay$stickerMergedMapVariable;");

//       videoMapVariables[i] = stickerMergedMapVariable;
//     }
//   }

//   // ADD XFADE TRANSITION
//   // TO DO: Add some condition

//   for (int i = 0; i < videoMapVariables.length - 1; i++) {
//     if (transitionMap.containsKey(i)) {
//       TransitionData transition = transitionMap[i]!;
//       if (transition.type == ETransitionType.xfade) {
//         final String xfadeMergedMapVariable = "[xfade_merged_$i]";
//         final String xfadeKey = transition.filterName!;

//         String prevVideoMapVariable = videoMapVariables[i]!;
//         String nextVideoMapVariable = videoMapVariables[i + 1]!;

//         final double xfadeDuration = xfadeDurationMap[i]!;

//         final double prevDuration = durationMap[i]!;
//         final double nextDuration = durationMap[i + 1]!;

//         filterStrings.add(
//             "$prevVideoMapVariable${nextVideoMapVariable}xfade=transition=$xfadeKey:duration=$xfadeDuration:offset=$prevDuration$xfadeMergedMapVariable;");

//         videoMapVariables[i] = null;
//         videoMapVariables[i + 1] = xfadeMergedMapVariable;

//         durationMap[i] = 0;
//         durationMap[i + 1] = prevDuration + nextDuration;
//       }
//     }
//   }

//   // generate video merge & scale command
//   String mergeTargetStr = "";
//   int mergeCount = 0;
//   for (final String? videoOutputStr in videoMapVariables.values) {
//     if (videoOutputStr != null) {
//       mergeTargetStr += videoOutputStr;
//       mergeCount++;
//     }
//   }

//   String currentOutputMapVariable = "[merged]";
//   filterStrings.add("${mergeTargetStr}concat=n=$mergeCount[merged];");

//   // ADD OVERLAY TRANSITION
//   // TO DO: Add some condition
//   double currentDuration = 0;
//   int transitionCount = 0;
//   for (int i = 0; i < videoMapVariables.length - 1; i++) {
//     if (videoMapVariables[i] == null) continue;

//     final double duration = durationMap[i]!;
//     currentDuration += duration;

//     if (transitionMap.containsKey(i)) {
//       TransitionData transition = transitionMap[i]!;
//       if (transition.type == ETransitionType.overlay) {
//         String transitionMapVariable = "[transition${transitionCount++}]";
//         String transitionMergedMapVariable = "[transition_merged_$i]";

//         final CropData cropData =
//             generateCropData(transition.width!, transition.height!);

//         inputArguments.addAll([
//           "-c:v",
//           "libvpx-vp9",
//           "-itsoffset",
//           (currentDuration - transition.transitionPoint!).toString(),
//           "-i",
//           "$appDirPath/${transition.filename!}"
//         ]);
//         filterStrings.add(
//             "[${inputFileCount++}:v]scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$transitionMapVariable;");
//         filterStrings.add(
//             "$currentOutputMapVariable${transitionMapVariable}overlay$transitionMergedMapVariable;");

//         currentOutputMapVariable = transitionMergedMapVariable;
//       }
//     }
//   }

//   // generate -filter_complex
//   String filterComplexStr = "";
//   for (final String filterStr in filterStrings) {
//     filterComplexStr += filterStr;
//   }

//   if (filterComplexStr.endsWith(";")) {
//     filterComplexStr =
//         filterComplexStr.substring(0, filterComplexStr.length - 1);
//   }

//   arguments.addAll(inputArguments);
//   arguments.addAll(["-filter_complex", filterComplexStr]);
//   arguments.addAll([
//     "-map",
//     currentOutputMapVariable,
//     "-c:a",
//     "aac",
//     "-c:v",
//     "libx264",
//     "-preset",
//     "superfast",
//     "-maxrate",
//     "5M",
//     "-bufsize",
//     "5M",
//     "-pix_fmt",
//     "yuv420p",
//     outputPath,
//     "-y"
//   ]);

//   return GenerateArgumentResponse(
//       arguments, outputPath, (totalDuration * framerate).floor());
// }

// Future<GenerateArgumentResponse> generateAudioRenderArgument(
//     TemplateData templateData, List<MediaData> list) async {
//   final List<String> arguments = <String>[];
//   final String appDirPath = await getAppDirectoryPath();
//   String outputPath = "$appDirPath/audio_out.m4a";
//   double totalDuration = 0;

//   List<String> audioOutputList = <String>[];
//   final List<String> inputArguments = <String>[];
//   final List<String> filterStrings = <String>[];
//   double currentDuration = 0;

//   for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
//     final SceneData sceneData = templateData.scenes[i];
//     final MediaData mediaData = list[i];

//     if (mediaData.type == EMediaType.video) {
//       int idx = audioOutputList.length;

//       inputArguments.addAll(["-i", mediaData.absolutePath]);
//       filterStrings.add(
//           "[$idx:a]atrim=0:${sceneData.duration},adelay=${currentDuration * 1000}[aud$idx];");
//       audioOutputList.add("[aud$idx]");
//     }

//     currentDuration += sceneData.duration;
//     totalDuration += sceneData.duration;
//   }
//   inputArguments.addAll(["-i", "$appDirPath/${templateData.music.filename}"]);

//   String filterComplexStr = "";
//   if (audioOutputList.isNotEmpty) {
//     for (final String filterStr in filterStrings) {
//       filterComplexStr += filterStr;
//     }

//     String mergeTargetStr = "";
//     for (final String audioOutputStr in audioOutputList) {
//       mergeTargetStr += audioOutputStr;
//     }
//     final int audioInputCount = audioOutputList.length;

//     filterComplexStr +=
//         "[$audioInputCount:a]atrim=0:$totalDuration[bgm];$mergeTargetStr[bgm]amix=inputs=${audioInputCount + 1}[out]";
//   } else {
//     filterComplexStr += "[0:a]atrim=0:$totalDuration[out]";
//   }

//   arguments.addAll(inputArguments);
//   arguments.addAll(["-filter_complex", filterComplexStr]);
//   arguments.addAll(
//       ["-map", "[out]", "-c:a", "aac", "-b:a", "256k", outputPath, "-y"]);

//   return GenerateArgumentResponse(arguments, outputPath, null);
// }

Future<GenerateArgumentResponse> generateMergeArgument(
    String videoPath, String audioPath) async {
  final String appDirPath = await getAppDirectoryPath();
  String outputPath = "$appDirPath/result.mp4";

  return GenerateArgumentResponse([
    "-i",
    videoPath,
    "-i",
    audioPath,
    "-c",
    "copy",
    "-map",
    "0:v:0",
    "-map",
    "1:a:0",
    outputPath,
    "-y"
  ], outputPath, 0);
}
