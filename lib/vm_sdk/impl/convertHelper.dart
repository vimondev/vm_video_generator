import 'dart:convert';

import 'package:myapp/vm_sdk/types/resource.dart';
import 'package:uuid/uuid.dart';
import '../types/global.dart';
import '../types/text.dart';
import 'global_helper.dart';

Future<String> parseAutoEditedDataToJSON(
    AutoEditedData autoEditedData, TextExportData exportedText) async {
  final uuid = Uuid();
  final String appDirPath = await getAppDirectoryPath();

  List<Map> slides = [];
  List<Map> bgm = [];
  List<Map> overlays = [];
  List<Map> frames = [];
  List<Map> transitions = [];

  for (int i = 0; i < autoEditedData.editedMediaList.length; i++) {
    EditedMedia editedMedia = autoEditedData.editedMediaList[i];
    FrameData? frameData = editedMedia.frame;
    StickerData? stickerData = editedMedia.sticker;
    TransitionData? transitionData = editedMedia.transition;

    String slideKey = uuid.v4();

    slides.add({
      "slideKey": slideKey,
      "order": i,
      "localPath": editedMedia.mediaData.absolutePath,
      "networkPath": null,
      "type":
          editedMedia.mediaData.type == EMediaType.image ? "image" : "video",
      "startTime": editedMedia.startTime,
      "endTime": editedMedia.startTime + editedMedia.duration,
      "angle": 0,
      "zoomX": editedMedia.zoomX,
      "zoomY": editedMedia.zoomY,
      "translateX": editedMedia.translateX,
      "translateY": editedMedia.translateY,
      "volume": 1,
      "playbackSpeed": 1,
      "flip": null
    });

    if (i == 0) {
      overlays.add({
        "id": uuid.v4(),
        "type": "TEXT",
        "rect": {
          "x": exportedText.x,
          "y": exportedText.y,
          "width": exportedText.width,
          "height": exportedText.height
        },
        "stickerData": {
          "localData": {
            "id": exportedText.id.toString(),
            "type": "TEXT",
            "filePath": exportedText.previewImagePath
          },
          "payload": exportedText.texts
        },
        "scale": exportedText.scale,
        "angle": 0,
        "slideKey": slideKey
      });
    }

    if (stickerData != null) {
      overlays.add({
        "id": uuid.v4(),
        "type": "STICKER",
        "rect": {
          "x": stickerData.x,
          "y": stickerData.y,
          "width": stickerData.fileinfo!.width,
          "height": stickerData.fileinfo!.height
        },
        "stickerData": {
          "localData": {
            "resourceId": stickerData.key,
            "type": "STICKER",
            "filePath": null
          },
          "payload": null
        },
        "scale": 1,
        "angle": 0,
        "slideKey": slideKey
      });
    }

    if (frameData != null) {
      frames.add({
        "id": uuid.v4(),
        "name": frameData.key,
        "resourceId": frameData.key,
        "slideKey": slideKey,
        "localPath": null,
        "networkPath": null
      });
    }

    if (transitionData != null) {
      if (transitionData.type == ETransitionType.xfade) {
        XFadeTransitionData xFadeTransitionData =
            transitionData as XFadeTransitionData;
        transitions.add({
          "id": uuid.v4(),
          "name": xFadeTransitionData.filterName,
          "type": "graphics",
          "slideKey": slideKey
        });
      } //
      else if (transitionData.type == ETransitionType.overlay) {
        OverlayTransitionData overlayTransitionData =
            transitionData as OverlayTransitionData;
        transitions.add({
          "id": uuid.v4(),
          "name": overlayTransitionData.key,
          "resourceId": overlayTransitionData.key,
          "type": "advance",
          "slideKey": slideKey,
          "localPath": null,
          "networkPath": null
        });
      }
    }
  }

  double currentTime = 0;
  for (int i = 0; i < autoEditedData.musicList.length; i++) {
    MusicData music = autoEditedData.musicList[i];
    bgm.add({
      "sourcePath": "$appDirPath/${music.filename}",
      "order": i,
      "startTime": currentTime,
      "endTime": currentTime + music.duration,
      "volume": 1.0,
      "inPoint": 0
    });

    currentTime += music.duration;
  }

  return json.encode({
    "width": autoEditedData.resolution.width,
    "height": autoEditedData.resolution.height,
    "ratio": autoEditedData.ratio.toString(),
    "timeline": {
      "slides": slides,
      "bgm": bgm
    },
    "overlays": overlays,
    "frames": frames,
    "transitions": transitions
  });
}
