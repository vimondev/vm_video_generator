import '../types/types.dart';
import 'global_helper.dart';

class GenerateArgumentResponse {
  List<String> arguments;
  String outputPath;
  double? totalDuration;

  GenerateArgumentResponse(this.arguments, this.outputPath, this.totalDuration);
}

Future<GenerateArgumentResponse> generateVideoRenderArgument(
    TemplateData templateData, List<MediaData> list) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  String outputPath = "$appDirPath/video_out.mp4";
  double totalDuration = 0;

  Map<int, String> videoMapVariables = <int, String>{}; // ex) [vid0]
  Map<int, double> durationMap = <int, double>{}; // scene duration

  int inputFileCount = 0;
  final List<String> inputArguments = <String>[]; // -i arguments
  final List<String> filterStrings = <String>[]; // -filter_complex strings

  // INPUT IMAGE & VIDEO
  for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
    final SceneData sceneData = templateData.scenes[i];
    final MediaData mediaData = list[i];

    String trimStr = "";
    if (mediaData.type == EMediaType.image) {
      inputArguments.addAll(
          ["-framerate", "30", "-loop", "1", "-t", "${sceneData.duration}"]);
    } else {
      trimStr = "trim=0:${sceneData.duration},setpts=PTS-STARTPTS,";
    }
    inputArguments.addAll(["-i", mediaData.absolutePath]);
    inputFileCount++;

    filterStrings.add("[$i:v]${trimStr}scale=1080:1080[vid$i];");
    videoMapVariables[i] = "[vid$i]";

    totalDuration += sceneData.duration;
    durationMap[i] = sceneData.duration;
  }

  // ADD FILTER (i => scene index)
  int filterCount = 0;

  for (int i = 0; i < videoMapVariables.length; i++) {
    // TO DO: Add some condition
    if (i % 2 == 0) {
      final double duration = durationMap[i]!;
      final String currentVideoMapVariable = videoMapVariables[i]!;

      // TO DO: Add some filter select logic
      String? filterKey = templateData.filterDatas.entries.first.key;
      FilterData? filter = templateData.filterDatas[filterKey];

      if (filter != null) {
        // TO DO: Duplicate filter caching
        final int loopCount = (duration / filter.duration).floor();
        String filterMapVariable = "[filter${filterCount++}]";
        String filterMergedMapVariable = "[filter_merged_$i]";

        inputArguments.addAll([
          "-stream_loop",
          loopCount.toString(),
          "-c:v",
          "libvpx-vp9",
          "-i",
          "$appDirPath/${filter.filename}"
        ]);
        filterStrings.add(
            "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=1080:1080$filterMapVariable;");
        filterStrings.add(
            "$currentVideoMapVariable${filterMapVariable}overlay$filterMergedMapVariable;");

        videoMapVariables[i] = filterMergedMapVariable;
      }
    }
  }

  // ADD XFADE TRANSITION
  // TO DO: Add some condition

  // generate video merge & scale command
  String mergeTargetStr = "";
  for (final String videoOutputStr in videoMapVariables.values) {
    mergeTargetStr += videoOutputStr;
  }

  String currentOutputMapVariable = "[scaled]";
  filterStrings.add(
      "${mergeTargetStr}concat=n=${videoMapVariables.length}[merged];[merged]scale=1080:1080[scaled];");

  // ADD OVERLAY TRANSITION
  // TO DO: Add some condition
  double currentDuration = 0;
  int transitionCount = 0;
  for (int i = 0; i < videoMapVariables.length - 1; i++) {
    final double duration = durationMap[i]!;
    currentDuration += duration;
    // TO DO: Add some condition
    if (i % 2 == 0) {
      // TO DO: Add some filter select logic
      String? transitionKey = templateData.transitionDatas.entries.first.key;
      TransitionData? transition = templateData.transitionDatas[transitionKey];

      if (transition != null) {
        String transitionMapVariable = "[transition${transitionCount++}]";
        String transitionMergedMapVariable = "[transition_merged_$i]";

        inputArguments.addAll([
          "-c:v",
          "libvpx-vp9",
          "-itsoffset",
          (currentDuration - transition.transitionPoint).toString(),
          "-i",
          "$appDirPath/${transition.filename!}"
        ]);
        filterStrings.add(
            "[${inputFileCount++}:v]scale=1080:1080$transitionMapVariable;");
        filterStrings.add(
            "$currentOutputMapVariable${transitionMapVariable}overlay$transitionMergedMapVariable;");

        currentOutputMapVariable = transitionMergedMapVariable;
      }
    }
  }

  // generate -filter_complex
  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
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
    "-c:a",
    "aac",
    "-c:v",
    "libx264",
    "-maxrate",
    "5M",
    "-bufsize",
    "5M",
    "-pix_fmt",
    "yuv420p",
    outputPath,
    "-y"
  ]);

  return GenerateArgumentResponse(arguments, outputPath, totalDuration);
}

Future<GenerateArgumentResponse> generateAudioRenderArgument(
    TemplateData templateData, List<MediaData> list) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  String outputPath = "$appDirPath/audio_out.m4a";
  double totalDuration = 0;

  List<String> audioOutputList = <String>[];
  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];
  double currentDuration = 0;

  for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
    final SceneData sceneData = templateData.scenes[i];
    final MediaData mediaData = list[i];

    if (mediaData.type == EMediaType.video) {
      int idx = audioOutputList.length;

      inputArguments.addAll(["-i", mediaData.absolutePath]);
      filterStrings.add(
          "[$idx:a]atrim=0:${sceneData.duration},adelay=${currentDuration * 1000}[aud$idx];");
      audioOutputList.add("[aud$idx]");
    }

    currentDuration += sceneData.duration;
    totalDuration += sceneData.duration;
  }
  inputArguments.addAll(["-i", "$appDirPath/${templateData.music}"]);

  String filterComplexStr = "";
  if (audioOutputList.isNotEmpty) {
    for (final String filterStr in filterStrings) {
      filterComplexStr += filterStr;
    }

    String mergeTargetStr = "";
    for (final String audioOutputStr in audioOutputList) {
      mergeTargetStr += audioOutputStr;
    }
    final int audioInputCount = audioOutputList.length;

    filterComplexStr +=
        "[$audioInputCount:a]atrim=0:$totalDuration[bgm];$mergeTargetStr[bgm]amix=inputs=${audioInputCount + 1}[out]";
  } else {
    filterComplexStr += "[0:a]atrim=0:$totalDuration[out]";
  }

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll(
      ["-map", "[out]", "-c:a", "aac", "-b:a", "256k", outputPath, "-y"]);

  return GenerateArgumentResponse(arguments, outputPath, totalDuration);
}

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
