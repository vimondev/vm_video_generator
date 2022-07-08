import 'dart:convert';
import 'package:myapp/vm_sdk/types/resource.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../types/global.dart';
import '../types/text.dart';
import 'resource_manager.dart';

String parseAllEditedDataToJSON(AllEditedData allEditedData) {
  final uuid = Uuid();

  List<Map> slides = [];
  List<Map> bgm = [];
  List<Map> overlays = [];
  List<Map> frames = [];
  List<Map> transitions = [];

  for (int i = 0; i < allEditedData.editedMediaList.length; i++) {
    EditedMedia editedMedia = allEditedData.editedMediaList[i];
    FrameData? frameData = editedMedia.frame;
    List<EditedStickerData> stickerDataList = editedMedia.stickers;
    TransitionData? transitionData = editedMedia.transition;
    TextExportData? exportedText = editedMedia.exportedText;

    String slideKey = uuid.v4();

    slides.add({
      "slideKey": slideKey,
      "order": i,
      "localPath": editedMedia.mediaData.absolutePath,
      "networkPath": null,
      "type":
          editedMedia.mediaData.type == EMediaType.image ? "image" : "video",
      "mediaWidth": editedMedia.mediaData.width,
      "mediaHeight": editedMedia.mediaData.height,
      "mediaDuration": editedMedia.mediaData.duration,
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

    if (exportedText != null) {
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

    for (int j = 0; j < stickerDataList.length; j++) {
      final EditedStickerData stickerData = stickerDataList[j];
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
          "name": xFadeTransitionData.key,
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
  for (int i = 0; i < allEditedData.musicList.length; i++) {
    MusicData music = allEditedData.musicList[i];
    bgm.add({
      "sourcePath": music.absolutePath,
      "order": i,
      "startTime": currentTime,
      "endTime": currentTime + music.duration,
      "volume": 1.0,
      "inPoint": 0
    });

    currentTime += music.duration;
  }

  return json.encode({
    "width": allEditedData.resolution.width,
    "height": allEditedData.resolution.height,
    "ratio": allEditedData.ratio.toString(),
    "timeline": {"slides": slides, "bgm": bgm},
    "overlays": overlays,
    "frames": frames,
    "transitions": transitions
  });
}

AllEditedData parseJSONToAllEditedData(String encodedJSON) {
  final AllEditedData allEditedData = AllEditedData();
  final Map parsedMap = json.decode(encodedJSON);

  final String ratio = parsedMap["ratio"];
  switch (ratio) {
    case "ERatio.ratio169":
      allEditedData.ratio = ERatio.ratio169;
      break;
    case "ERatio.ratio916":
      allEditedData.ratio = ERatio.ratio916;
      break;
    case "ERatio.ratio11":
    default:
      allEditedData.ratio = ERatio.ratio11;
      break;
  }
  allEditedData.resolution = Resolution.fromRatio(allEditedData.ratio);

  Map slideMap = {};

  List slides = parsedMap["timeline"]["slides"];
  List bgm = parsedMap["timeline"]["bgm"];

  List overlays = parsedMap["overlays"];
  List frames = parsedMap["frames"];
  List transitions = parsedMap["transitions"];

  for (int i = 0; i < slides.length; i++) {
    final Map slide = slides[i];
    final String slideKey = slide["slideKey"];

    final EMediaType type =
        slide["type"] == "image" ? EMediaType.image : EMediaType.video;
    double? duration;
    if (slide["mediaDuration"] != null) {
      duration = slide["mediaDuration"] * 1.0;
    }

    final MediaData mediaData = MediaData(
        slide["localPath"],
        type,
        slide["mediaWidth"],
        slide["mediaHeight"],
        duration,
        DateTime.now(),
        "",
        null);

    final EditedMedia editedMedia = EditedMedia(mediaData);

    editedMedia.startTime = slide["startTime"] * 1.0;
    editedMedia.duration = slide["endTime"] * 1.0 - editedMedia.startTime;
    editedMedia.translateX = slide["translateX"];
    editedMedia.translateY = slide["translateY"];
    editedMedia.zoomX = slide["zoomX"] * 1.0;
    editedMedia.zoomY = slide["zoomY"] * 1.0;
    editedMedia.angle = slide["angle"] * 1.0;
    editedMedia.volume = slide["volume"] * 1.0;
    editedMedia.playbackSpeed = slide["playbackSpeed"] * 1.0;

    allEditedData.editedMediaList.add(editedMedia);
    slideMap[slideKey] = editedMedia;
  }

  for (int i = 0; i < overlays.length; i++) {
    final Map overlay = overlays[i];
    final String slideKey = overlay["slideKey"];

    if (slideMap.containsKey(slideKey)) {
      EditedMedia editedMedia = slideMap[slideKey];

      if (overlay["type"] == "STICKER") {
        final String stickerKey =
            overlay["stickerData"]["localData"]["resourceId"];
        final StickerData? stickerData =
            ResourceManager.getInstance().getStickerData(stickerKey);

        if (stickerData != null) {
          final EditedStickerData editedStickerData = EditedStickerData(stickerData);

          editedStickerData.x = overlay["rect"]["x"] * 1.0;
          editedStickerData.y = overlay["rect"]["y"] * 1.0;
          editedStickerData.scale = overlay["scale"] * 1.0;
          editedStickerData.rotate = overlay["angle"] * 1.0;

          editedMedia.stickers.add(editedStickerData);
        }
      } //
      else if (overlay["type"] == "TEXT") {
        // TO DO
      }
    }
  }

  for (int i = 0; i < frames.length; i++) {
    final Map frame = frames[i];
    final String slideKey = frame["slideKey"];

    if (slideMap.containsKey(slideKey)) {
      EditedMedia editedMedia = slideMap[slideKey];

      final String frameKey = frame["name"];
      final FrameData? frameData =
          ResourceManager.getInstance().getFrameData(frameKey);

      if (frameData != null) {
        editedMedia.frame = frameData;
      }
    }
  }

  for (int i = 0; i < transitions.length; i++) {
    final Map transition = transitions[i];
    final String slideKey = transition["slideKey"];

    if (slideMap.containsKey(slideKey)) {
      EditedMedia editedMedia = slideMap[slideKey];

      final String transitionKey = transition["name"];
      final TransitionData? transitionData =
          ResourceManager.getInstance().getTransitionData(transitionKey);

      if (transitionData != null) {
        editedMedia.transition = transitionData;

        final String type = transition["type"];
        if (type == "graphics") {
          editedMedia.xfadeDuration = 1;
        }
      }
    }
  }

  for (int i = 0; i < bgm.length; i++) {
    final Map bgmItem = bgm[i];

    MusicData musicData = MusicData();
    musicData.absolutePath = bgmItem["sourcePath"];
    musicData.filename = basename(musicData.absolutePath!);
    musicData.startTime = bgmItem["startTime"] * 1.0;
    musicData.duration = bgmItem["endTime"] * 1.0 - musicData.startTime;

    allEditedData.musicList.add(musicData);
  }

  // TextExportData? exportedText;
  // TextExportData textExportData = TextExportData()

  return allEditedData;
}
