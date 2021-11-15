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

  List<String> videoOutputList = <String>[];
  final List<String> inputArguments = <String>[];
  final List<String> filterStrings = <String>[];

  for (int i = 0; i < list.length && i < templateData.scenes.length; i++) {
    final SceneData sceneData = templateData.scenes[i];
    final MediaData mediaData = list[i];

    String trimStr = "";
    totalDuration += sceneData.duration;

    if (mediaData.type == EMediaType.image) {
      inputArguments.addAll(
          ["-framerate", "30", "-loop", "1", "-t", "${sceneData.duration}"]);
    } else {
      trimStr = "trim=0:${sceneData.duration},setpts=PTS-STARTPTS,";
    }
    inputArguments.addAll(["-i", mediaData.absolutePath]);

    filterStrings.add("[$i:v]${trimStr}scale=1920:1080[vid$i];");
    videoOutputList.add("[vid$i]");
  }

  String filterComplexStr = "";
  for (final String filterStr in filterStrings) {
    filterComplexStr += filterStr;
  }

  String mergeTargetStr = "";
  for (final String videoOutputStr in videoOutputList) {
    mergeTargetStr += videoOutputStr;
  }
  filterComplexStr +=
      "${mergeTargetStr}concat=n=${videoOutputList.length}[merged];[merged]scale=1920:1080[out]";

  arguments.addAll(inputArguments);
  arguments.addAll(["-filter_complex", filterComplexStr]);
  arguments.addAll([
    "-map",
    "[out]",
    "-c:a",
    "aac",
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
