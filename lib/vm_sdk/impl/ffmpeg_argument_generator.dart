import '../types/types.dart';
import 'global_helper.dart';

int videoWidth = 1920;
int videoHeight = 1080;
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
    TemplateData templateData,
    ExportedTitlePNGSequenceData exportedTitle,
    List<MediaData> list) async {
  final List<String> arguments = <String>[];
  final String appDirPath = await getAppDirectoryPath();
  String outputPath = "$appDirPath/video_out.mp4";
  double totalDuration = 0;

  Map<int, String> videoMapVariables = <int, String>{}; // ex) [vid0]
  Map<int, double> durationMap = <int, double>{}; // scene duration
  Map<int, FilterData> filterMap = <int, FilterData>{};
  Map<int, TransitionData> transitionMap = <int, TransitionData>{};

  int inputFileCount = 0;
  final List<String> inputArguments = <String>[]; // -i arguments
  final List<String> filterStrings = <String>[]; // -filter_complex strings

  // INPUT IMAGE & VIDEO
  for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
    final SceneData sceneData = templateData.scenes[i];
    final MediaData mediaData = list[i];

    String trimStr = "";
    if (mediaData.type == EMediaType.image) {
      inputArguments.addAll([
        "-framerate",
        "$framerate",
        "-loop",
        "1",
        "-t",
        "${sceneData.duration}"
      ]);
    } else {
      trimStr =
          "fps=$framerate,trim=0:${sceneData.duration},setpts=PTS-STARTPTS,";
    }
    inputArguments.addAll(["-i", mediaData.absolutePath]);
    inputFileCount++;

    final CropData cropData =
        generateCropData(mediaData.width, mediaData.height);

    filterStrings.add(
        "[$i:v]${trimStr}scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY},setdar=dar=${videoWidth / videoHeight}[vid$i];");
    videoMapVariables[i] = "[vid$i]";

    totalDuration += sceneData.duration;
    durationMap[i] = sceneData.duration;

    if (sceneData.filterKey != null &&
        templateData.filterDatas.containsKey(sceneData.filterKey)) {
      filterMap[i] = templateData.filterDatas[sceneData.filterKey]!;
    }
    if (sceneData.transitionKey != null &&
        templateData.transitionDatas.containsKey(sceneData.transitionKey)) {
      transitionMap[i] = templateData.transitionDatas[sceneData.transitionKey]!;
    }
  }

  // ADD FILTER (i => scene index)
  int filterCount = 0;

  for (int i = 0; i < videoMapVariables.length; i++) {
    if (filterMap.containsKey(i)) {
      final double duration = durationMap[i]!;
      final String currentVideoMapVariable = videoMapVariables[i]!;
      FilterData filter = filterMap[i]!;

      final int loopCount = (duration / filter.duration).floor();
      String filterMapVariable = "[filter${filterCount++}]";
      String filterMergedMapVariable = "[filter_merged_$i]";

      final CropData cropData = generateCropData(filter.width, filter.height);

      inputArguments.addAll([
        "-stream_loop",
        loopCount.toString(),
        "-c:v",
        "libvpx-vp9",
        "-i",
        "$appDirPath/${filter.filename}"
      ]);
      filterStrings.add(
          "[${inputFileCount++}:v]trim=0:$duration,setpts=PTS-STARTPTS,scale=${cropData.scaledWidth}:${cropData.scaledHeight},crop=$videoWidth:$videoHeight:${cropData.cropPosX}:${cropData.cropPosY}$filterMapVariable;");
      filterStrings.add(
          "$currentVideoMapVariable${filterMapVariable}overlay$filterMergedMapVariable;");

      videoMapVariables[i] = filterMergedMapVariable;
    }
  }

  // ADD TITLE

  exportedTitle.width = (exportedTitle.width * 1.5).floor();
  exportedTitle.height = (exportedTitle.height * 1.5).floor();

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
      "[${inputFileCount++}:v]trim=0:${durationMap[0]!},setpts=PTS-STARTPTS,scale=${exportedTitle.width}:${exportedTitle.height}$titleMapVariable;");
  filterStrings.add(
      "${videoMapVariables[0]!}${titleMapVariable}overlay=$currentPosX:$startPosY$titleMergedMapVariable;");

  videoMapVariables[0] = titleMergedMapVariable;

  // ADD XFADE TRANSITION
  // TO DO: Add some condition

  // generate video merge & scale command
  String mergeTargetStr = "";
  for (final String videoOutputStr in videoMapVariables.values) {
    mergeTargetStr += videoOutputStr;
  }

  String currentOutputMapVariable = "[merged]";
  filterStrings
      .add("${mergeTargetStr}concat=n=${videoMapVariables.length}[merged];");

  // ADD OVERLAY TRANSITION
  // TO DO: Add some condition
  double currentDuration = 0;
  int transitionCount = 0;
  for (int i = 0; i < videoMapVariables.length - 1; i++) {
    final double duration = durationMap[i]!;
    currentDuration += duration;

    if (transitionMap.containsKey(i)) {
      TransitionData transition = transitionMap[i]!;
      String transitionMapVariable = "[transition${transitionCount++}]";
      String transitionMergedMapVariable = "[transition_merged_$i]";

      final CropData cropData =
          generateCropData(transition.width, transition.height);

      inputArguments.addAll([
        "-c:v",
        "libvpx-vp9",
        "-itsoffset",
        (currentDuration - transition.transitionPoint).toString(),
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
  inputArguments.addAll(["-i", "$appDirPath/${templateData.music.filename}"]);

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

  return GenerateArgumentResponse(arguments, outputPath, null);
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
