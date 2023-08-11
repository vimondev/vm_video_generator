import 'dart:convert';
import 'dart:math';
import 'package:myapp/vm_sdk/types/resource.dart';
import 'package:path/path.dart';
import 'package:uuid/uuid.dart';
import '../types/global.dart';
import '../types/text.dart';
import 'resource_manager.dart';
import 'vm_text_widget.dart';

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
    List<GiphyStickerData> giphyStickerDataList = editedMedia.giphyStickers;
    List<CanvasTextData> canvasTextList = editedMedia.canvasTexts;
    TransitionData? transitionData = editedMedia.transition;
    List<EditedTextData> textList = editedMedia.editedTexts;

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
      "mediaThumbnail": editedMedia.thumbnailPath,
      "startTime": editedMedia.startTime,
      "endTime": editedMedia.startTime + editedMedia.duration,
      "angle": 0,
      // "zoomX": editedMedia.zoomX,
      // "zoomY": editedMedia.zoomY,
      // "translateX": editedMedia.translateX,
      // "translateY": editedMedia.translateY,
      "volume": 1,
      "playbackSpeed": 1,
      "vflip": editedMedia.vflip,
      "hflip": editedMedia.hflip,
      "rect": {
        "l": editedMedia.cropLeft,
        "t": editedMedia.cropTop,
        "r": editedMedia.cropRight,
        "b": editedMedia.cropBottom,
      }
    });

    for (int i = 0; i < textList.length; i++) {
      final EditedTextData editedText = textList[i];
      final TextExportData? exportedText = editedText.textExportData;

      if (exportedText != null) {
        final Map textDataMap = {};

        for (final key in exportedText.textDataMap.keys) {
          VMText vmText = exportedText.textDataMap[key]!;
          textDataMap[key] = {
            "key": vmText.key,
            "value": vmText.value,
            "boundingBox": {
              "x": vmText.boundingBox.x,
              "y": vmText.boundingBox.y,
              "width": vmText.boundingBox.width,
              "height": vmText.boundingBox.height
            }
          };
        }

        overlays.add({
          "id": uuid.v4(),
          "type": "TEXT",
          "rect": {
            "x": editedText.x,
            "y": editedText.y,
            "width": editedText.width,
            "height": editedText.height
          },
          "stickerData": {
            "localData": {
              "id": exportedText.id.toString(),
              "type": "TEXT",
              "filePath": exportedText.previewImagePath
            },
            "payload": editedText.texts,
            "textInfo": {
              "previewImagePath": exportedText.previewImagePath,
              "allSequencesPath": exportedText.allSequencesPath,
              "width": exportedText.width,
              "height": exportedText.height,
              "frameRate": exportedText.frameRate,
              "totalFrameCount": exportedText.totalFrameCount,
              "textDataMap": textDataMap,
            }
          },
          "scale": 1,
          "angle": 0,
          "slideKey": slideKey
        });
      }
    }

    for (int j = 0; j < canvasTextList.length; j++) {
      final CanvasTextData canvasTextData = canvasTextList[j];
      overlays.add({
        "id": uuid.v4(),
        "type": "CANVAS",
        "rect": {
          "x": canvasTextData.x,
          "y": canvasTextData.y,
          "width": canvasTextData.width,
          "height": canvasTextData.height
        },
        "stickerData": {
          "localData": {
            "id": uuid.v4(),
            "type": "CANVAS",
            "filePath": canvasTextData.imagePath
          },
          "payload": null
        },
        "scale": 1,
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

    // for (int j = 0; j < giphyStickerDataList.length; j++) {
    //   final GiphyStickerData giphyStickerData = giphyStickerDataList[j];
    //   overlays.add({
    //     "id": uuid.v4(),
    //     "type": "GIPHY_STICKER",
    //     "rect": {
    //       "x": giphyStickerData.x,
    //       "y": giphyStickerData.y,
    //       "width": giphyStickerData.width,
    //       "height": giphyStickerData.height
    //     },
    //     "stickerData": {
    //       "localData": {
    //         "id": uuid.v4(),
    //         "type": "GIPHY_STICKER",
    //         "filePath": giphyStickerData.gifPath
    //       },
    //       "payload": null
    //     },
    //     "scale": 1,
    //     "angle": 0,
    //     "slideKey": slideKey
    //   });
    // }

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
      "name": music.title,
      "sourcePath": music.absolutePath,
      "order": i,
      "startTime": currentTime,
      "endTime": currentTime + music.duration,
      "volume": music.volume,
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
        0,
        duration,
        DateTime.now(),
        "",
        null);

    final EditedMedia editedMedia = EditedMedia(mediaData);

    editedMedia.startTime = slide["startTime"] * 1.0;
    editedMedia.duration = slide["endTime"] * 1.0 - editedMedia.startTime;
    // editedMedia.translateX = slide["translateX"];
    // editedMedia.translateY = slide["translateY"];
    // editedMedia.zoomX = slide["zoomX"] * 1.0;
    // editedMedia.zoomY = slide["zoomY"] * 1.0;
    editedMedia.angle = slide["angle"] * 1.0;
    editedMedia.volume = slide["volume"] * 1.0;
    editedMedia.playbackSpeed = slide["playbackSpeed"] * 1.0;
    editedMedia.vflip = slide["vflip"] ?? false;
    editedMedia.hflip = slide["hflip"] ?? false;

    bool isNeedRecalculateCrop = false;
    if (slide["rect"] != null) {
      if (slide["rect"]["l"] != null) {
        editedMedia.cropLeft = slide["rect"]["l"] * 1.0;
      }
      else {
        isNeedRecalculateCrop = true;
      }

      if (slide["rect"]["t"] != null) {
        editedMedia.cropTop = slide["rect"]["t"] * 1.0;
      }
      else {
        isNeedRecalculateCrop = true;
      }

      if (slide["rect"]["r"] != null) {
        editedMedia.cropRight = slide["rect"]["r"] * 1.0;
      }
      else {
        isNeedRecalculateCrop = true;
      }
      
      if (slide["rect"]["b"] != null) {
        editedMedia.cropBottom = slide["rect"]["b"] * 1.0;
      }
      else {
        isNeedRecalculateCrop = true;
      }
    }
    else {
      isNeedRecalculateCrop = true;
    }

    if (isNeedRecalculateCrop) {
      int mediaWidth = max(1, editedMedia.mediaData.width);
      int mediaHeight = max(1, editedMedia.mediaData.height);

      double aspectRatio = (allEditedData.resolution.width * 1.0) / allEditedData.resolution.height;
      double baseCropWidth = aspectRatio;
      double baseCropHeight = 1;

      double scaleFactor = min(mediaWidth / baseCropWidth, mediaHeight / baseCropHeight);
      int cropWidth = (baseCropWidth * scaleFactor).floor();
      int cropHeight = (baseCropHeight * scaleFactor).floor();

      double cropLeft = (mediaWidth - cropWidth) / 2;
      double cropRight = cropLeft + cropWidth;
      double cropTop = (mediaHeight - cropHeight) / 2;
      double cropBottom = cropTop + cropHeight;

      editedMedia.cropLeft = cropLeft / mediaWidth;
      editedMedia.cropRight = cropRight / mediaWidth;
      editedMedia.cropTop = cropTop / mediaHeight;
      editedMedia.cropBottom = cropBottom / mediaHeight;
    }

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

          editedStickerData.width = (overlay["rect"]["width"] * 1.0).floor();
          editedStickerData.height = (overlay["rect"]["height"] * 1.0).floor();
          editedStickerData.x = overlay["rect"]["x"] * allEditedData.resolution.width * 1.0;
          editedStickerData.y = overlay["rect"]["y"] * allEditedData.resolution.height * 1.0;
          editedStickerData.rotate = overlay["angle"] * 1.0;

          editedMedia.stickers.add(editedStickerData);
        }
      } //
      else if (overlay["type"] == "GIPHY_STICKER") {
        final String gifPath = overlay["stickerData"]["localData"]["filePath"];
        final GiphyStickerData giphyStickerData = GiphyStickerData();

        giphyStickerData.gifPath = gifPath;
        giphyStickerData.width = (overlay["rect"]["width"] * 1.0).floor();
        giphyStickerData.height = (overlay["rect"]["height"] * 1.0).floor();
        giphyStickerData.x = overlay["rect"]["x"] * allEditedData.resolution.width * 1.0;
        giphyStickerData.y = overlay["rect"]["y"] * allEditedData.resolution.height * 1.0;
        giphyStickerData.rotate = overlay["angle"] * 1.0;

        editedMedia.giphyStickers.add(giphyStickerData);
      } //
      else if (overlay["type"] == "CANVAS") {
        final String imagePath = overlay["stickerData"]["localData"]["filePath"];
        final CanvasTextData canvasTextData = CanvasTextData();

        canvasTextData.imagePath = imagePath;
        canvasTextData.width = (overlay["rect"]["width"] * 1.0).floor();
        canvasTextData.height = (overlay["rect"]["height"] * 1.0).floor();
        canvasTextData.x = overlay["rect"]["x"] * allEditedData.resolution.width * 1.0;
        canvasTextData.y = overlay["rect"]["y"] * allEditedData.resolution.height * 1.0;
        canvasTextData.rotate = overlay["angle"] * 1.0;

        editedMedia.canvasTexts.add(canvasTextData);
      } //
      else if (overlay["type"] == "TEXT") {
        final String textId = overlay["stickerData"]["localData"]["id"];
        final Map payload = overlay["stickerData"]["payload"];

        final TextData? textData =
            ResourceManager.getInstance().getTextData(textId);

        if (textData != null) {
          EditedTextData editedTextData = EditedTextData(
              textId,
              overlay["rect"]["x"] * allEditedData.resolution.width * 1.0,
              overlay["rect"]["y"] * allEditedData.resolution.height * 1.0,
              overlay["rect"]["width"] * 1.0,
              overlay["rect"]["height"] * 1.0);
          editedTextData.rotate = overlay["angle"] * 1.0;

          if (payload.containsKey("#TEXT1")) {
            editedTextData.texts["#TEXT1"] = payload["#TEXT1"];
          }
          if (payload.containsKey("#TEXT2")) {
            editedTextData.texts["#TEXT2"] = payload["#TEXT2"];
          }

          editedMedia.editedTexts.add(editedTextData);
        }
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
    musicData.volume = bgmItem["volume"] * 1.0;

    allEditedData.musicList.add(musicData);
  }

  // TextExportData? exportedText;
  // TextExportData textExportData = TextExportData()

  return allEditedData;
}
