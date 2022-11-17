import 'global.dart';
import 'fetch.dart';

enum ETransitionType { xfade, overlay }
enum EStickerType { object }

class MusicData {
  String title = "";
  String filename = "";
  String speed = "";
  String url = "";
  String? absolutePath;
  double duration = 0;
  double startTime = 0;
}

class ResourceData {
  String key;
  bool isEnableAutoEdit = false;
  bool isRecommend = false;
  Map exceptSpeed = {};

  ResourceData(this.key);
  ResourceData.fromJson(this.key, Map map) {}
}

class TextData extends ResourceData {
  Map unsupportLang = {};

  TextData(String key) : super(key);
  TextData.fromJson(String key, Map map) : super(key) {
  }
}

class TransitionData extends ResourceData {
  ETransitionType type;

  TransitionData(String key, this.type)
      : super(key);
}

class XFadeTransitionData extends TransitionData {
  String filterName = "";
  XFadeTransitionData(String key, this.filterName)
      : super(key, ETransitionType.xfade);
  XFadeTransitionData.fromJson(String key, Map map)
      : super(key, ETransitionType.xfade) {
    filterName = map["filterName"];
  }
}

class ResourceFileInfo {
  int width;
  int height;
  double duration;
  SourceModel source;
  ResourceFileInfo(this.width, this.height, this.duration, this.source);
}

class TransitionFileInfo extends ResourceFileInfo {
  double transitionPoint;
  TransitionFileInfo(int width, int height, double duration,
      this.transitionPoint, SourceModel source)
      : super(width, height, duration, source);
}

class OverlayTransitionData extends TransitionData {
  Map<ERatio, TransitionFileInfo> fileMap = {};

  OverlayTransitionData(String key)
      : super(key, ETransitionType.overlay);
  OverlayTransitionData.fromFetchModel(
      String key, TransitionFetchModel fetchModel)
      : super(key, ETransitionType.overlay) {
    for (final ratio in fetchModel.sourceMap.keys) {
      Resolution resolution = Resolution.fromRatio(ratio);
      fileMap[ratio] = TransitionFileInfo(
          resolution.width,
          resolution.height,
          fetchModel.duration,
          fetchModel.transitionPoint,
          fetchModel.sourceMap[ratio]!);
    }
  }
}

class FrameData extends ResourceData {
  Map<ERatio, ResourceFileInfo> fileMap = {};
  EMediaLabel type = EMediaLabel.none;

  FrameData(String key) : super(key);
  FrameData.fromFetchModel(
      String key, FrameFetchModel fetchModel)
      : super(key) {
    for (final ratio in fetchModel.sourceMap.keys) {
      Resolution resolution = Resolution.fromRatio(ratio);
      fileMap[ratio] = ResourceFileInfo(resolution.width, resolution.height,
          fetchModel.duration, fetchModel.sourceMap[ratio]!);
      type = fetchModel.type;
    }
  }
}

class StickerData extends ResourceData {
  ResourceFileInfo? fileinfo;
  EMediaLabel type = EMediaLabel.none;

  StickerData(String key) : super(key);
  StickerData.fromFetchModel(
      String key, StickerFetchModel fetchModel)
      : super(key) {
    fileinfo = ResourceFileInfo(fetchModel.width, fetchModel.height,
        fetchModel.duration, fetchModel.source!);
    type = fetchModel.type;
  }
}

class EditedStickerData extends StickerData {
  int width = 0;
  int height = 0;
  double x = 0;
  double y = 0;
  double rotate = 0;

  EditedStickerData(StickerData stickerData)
      : super(stickerData.key) {
    fileinfo = stickerData.fileinfo;
    type = stickerData.type;
  }
}

class CanvasTextData {
  String imagePath = "";
  int width = 0;
  int height = 0;
  double x = 0;
  double y = 0;
  double rotate = 0;

  CanvasTextData();
}