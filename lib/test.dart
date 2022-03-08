import 'dart:io';

import 'package:flutter/material.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:myapp/vm_sdk/impl/lottie_text_widget.dart';
import 'package:myapp/vm_sdk/impl/title_helper.dart';
import 'vm_sdk/vm_sdk.dart';
import 'vm_sdk/types/types.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'dart:convert';
import 'vm_sdk/impl/lottie_widget.dart';
import 'package:flutter/services.dart' show rootBundle;

class TestWidget extends StatefulWidget {
  TestWidget({Key? key}) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  // final VMSDKWidget _vmsdkWidget = VMSDKWidget();
  late LottieTextWidget _lottieTextWidget = LottieTextWidget();

  TextEditingController _textController1 = TextEditingController();
  TextEditingController _textController2 = TextEditingController();

  List<String> imageList = [];
  double _width = 0;
  double _height = 0;
  Map<String, LottieText> _textDataMap = {};
  ETitleType? _title;
  bool _isPlaying = false;

  void _handlePressedTitleField () async {
    if (_textController1.text.isEmpty) {
    } else {
      String? preview = await _lottieTextWidget.setTextValue("#TEXT1", _textController1.text);

      setState(() {
        if (preview != null) imageList = [preview];
        _width = _lottieTextWidget.width;
        _height = _lottieTextWidget.height;
        _textDataMap = _lottieTextWidget.textDataMap;
      });
    }
    _textController1.clear();
  }

  void _handlePressedSubtitleField () async {
    if (_textController2.text.isEmpty) {
    } else {
      String? preview = await _lottieTextWidget.setTextValue("#TEXT2", _textController2.text);

      setState(() {
        if (preview != null) imageList = [preview];
        _width = _lottieTextWidget.width;
        _height = _lottieTextWidget.height;
        _textDataMap = _lottieTextWidget.textDataMap;
      });
    }
    _textController2.clear();
  }

  void _run() async {
    if (_isPlaying == true) return;
    _isPlaying = true;
    setState(() {
      imageList = [];
    });
    print('This is _run method of TestWidget');
    // final TitleData title = (await loadTitleData(ETitleType.title33))!;

    if (_title == null) {
      _title = ETitleType.title06;
    } else {
      bool isNext = false;
      for (var value in ETitleType.values) {
        if (isNext == true) {
          _title = value;
          break;
        }
        if (_title == value) {
          isNext = true;
        }
      }
      if (isNext == true && _title == ETitleType.title33) {
        _title = ETitleType.title06;
      }
    }

    final TitleData title = (await loadTitleData(_title!))!;
    print('title is ');

    print(title.json);
    print(title.fontFamily);
    print(title.fontBase64);
    print(title.texts);

    title.texts.addAll(["THIS IS VIMON V-LOG", "This is subtitle"]);

    _lottieTextWidget.setData(title);

    String? preview = await _lottieTextWidget.extractPreview();

    // preview = await _lottieTextWidget.setTextValue("#TEXT1", "이 앱은 VIIV입니다.");
    //
    // preview = await _lottieTextWidget.setTextValue("#TEXT2", "가나다라마바사아자차카타파하0123456789");

    setState(() {
      if (preview != null) imageList = [preview];
      _width = _lottieTextWidget.width;
      _height = _lottieTextWidget.height;
      _textDataMap = _lottieTextWidget.textDataMap;
    });
    print('TestWidget result preview is : $preview');

    // List<String>? sequences = await _lottieTextWidget.extractAllSequence();
    // print("test.dart - sequences : ");
    // if (sequences != null) {
    //   for (int i = 0; i < sequences.length; i++) {
    //     print(sequences[i]);
    //   }
    // }
    // setState(() {
    //   if (sequences != null) imageList = sequences;
    // });

    // if (!_vmsdkWidget.isInitialized) {
    //   await _vmsdkWidget.initialize();
    // }
    //
    // final String assetPath = "_test/set01";
    // final filelist =
    //     json.decode(await loadResourceString("$assetPath/test.json"));
    //
    // final List<MediaData> mediaList = <MediaData>[];
    //
    // for (final Map file in filelist) {
    //   final String filename = file["filename"];
    //   final EMediaType type =
    //       file["type"] == "image" ? EMediaType.image : EMediaType.video;
    //   final int width = file["width"];
    //   final int height = file["height"];
    //   DateTime createDate = DateTime.parse(file["createDate"]);
    //   String gpsString = file["gpsString"];
    //
    //   double? duration;
    //   if (file.containsKey("duration")) duration = file["duration"];
    //
    //   final mediaFile = await copyAssetToLocalDirectory("$assetPath/$filename");
    //   mediaList.add(MediaData(mediaFile.path, type, width, height, duration,
    //       createDate, gpsString, null));
    // }
    //
    // final String? videoPath = await _vmsdkWidget.generateVideo(
    //     mediaList,
    //     EMusicStyle.styleB,
    //     // ["THIS IS", "VIMON V-LOG"],
    //     ["THIS IS VIMON V-LOG"],
    //     (status, progress, estimatedTime) {});
    //
    // if (videoPath != null) {
    //   await GallerySaver.saveVideo(videoPath);
    // }
    _isPlaying = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("VM SDK TEST"),
      ),
      resizeToAvoidBottomInset: false,
      body: Container(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: 50,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textController1,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "Please enter Title",
                        ),
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _handlePressedTitleField,
                      child: Text("Apply"),
                    ),
                  ],
                ),
              ),
              Container(
                height: 50,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _textController2,
                        autofocus: false,
                        decoration: InputDecoration(
                          hintText: "Please enter Subtitle",
                        ),
                      ),
                    ),
                    Spacer(),
                    ElevatedButton(
                      onPressed: _handlePressedSubtitleField,
                      child: Text("Apply"),
                    ),
                  ],
                ),
              ),
              ListView.builder(
                itemCount: imageList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  bool isPreview = imageList.length == 1;
                  return Stack(
                    children: [
                      Container(
                        child: Image.file(
                          File(imageList[index]),
                          width: MediaQuery.of(context).size.width,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                      isPreview
                          ? CustomPaint(
                              foregroundPainter: RectanglePainter(
                                mediaWidth: MediaQuery.of(context).size.width,
                                width: _width,
                                height: _height,
                                textDataMap: _textDataMap,
                              ),
                            )
                          : Container(),
                    ],
                  );
                },
              ),
              _lottieTextWidget,
            ],
          ),
        ),
      ),
      backgroundColor: Colors.grey,
      floatingActionButton: FloatingActionButton(
          onPressed: _run, tooltip: 'Run', child: const Icon(Icons.play_arrow)),
    );
  }
}

class RectanglePainter extends CustomPainter {
  double mediaWidth;
  double width;
  double height;
  Map<String, LottieText> textDataMap;

  RectanglePainter(
      {required this.mediaWidth,
      required this.width,
      required this.height,
      required this.textDataMap});

  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
    final paint = Paint()
      ..color = Colors.amber
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;

    int length = textDataMap.length;
    for (int i = 0; i < textDataMap.length; i++) {
      Rectangle rectangle = textDataMap[i.toString()]!.boundingBox;

      final mediaHeight = height * mediaWidth / width;

      final x = mediaWidth * rectangle.x / width;
      final y = mediaHeight * rectangle.y / height;

      final x2 = mediaWidth * (rectangle.x + rectangle.width) / width;
      final y2 = mediaHeight * (rectangle.y + rectangle.height) / height;

      print(
          'x : $x, y : $y, x2 : $x2, y2 : $y2, width : $width, height: $height, mediaWidth : $mediaWidth, mediaHeight : $mediaHeight, rect.x : ${rectangle.x}, rect.y : ${rectangle.y}, rect.width : ${rectangle.width}, rect.height : ${rectangle.height} ');

      final a = Offset(x, y);
      final b = Offset(x2, y2);

      Rect rect = Rect.fromPoints(a, b);
      // canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }
}
