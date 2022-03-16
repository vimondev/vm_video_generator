import 'dart:io';
import 'dart:async';

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

  List<String> imageList = [];
  double _width = 0;
  double _height = 0;
  Map<String, LottieText> _textDataMap = {};
  ETitleType? _title;
  bool _isPlaying = false;

  void callback(number, textController) async {
    String? preview =
    await _lottieTextWidget.setTextValue("#TEXT$number", textController.text);

    setState(() {
      if (preview != null) imageList = [preview];
      _width = _lottieTextWidget.width;
      _height = _lottieTextWidget.height;
      _textDataMap = _lottieTextWidget.textDataMap;
    });
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
    // print('title is ');
    //
    // print(title.json);
    // print(title.fontFamily);
    // print(title.fontBase64);
    // print(title.texts);

    title.texts.addAll(["THIS IS VIMON V-LOG", "This is subtitle"]);

    _lottieTextWidget.setData(title);

    await _lottieTextWidget.extractPreview();
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
    // print('TestWidget result preview is : $preview');

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

    print('title is $_title');
    _isPlaying = false;
  }

  List<Widget> RectangleBoxList(isPreview, index) {
    List<Widget> list = [];

    list.add(Container(
      child: Image.file(
        File(imageList[index]),
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.fitWidth,
      ),
    ));

    if (isPreview) {
      for (int i = 0; i < _textDataMap.length; i++) {
        list.add(RectangleBox(
          mediaWidth: MediaQuery.of(context).size.width,
          width: _width,
          height: _height,
          lottieText: _textDataMap[i.toString()]!,
          textDataMapIndex: i,
          callback: callback,
        ));
      }
    }
    return list;
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
              ListView.builder(
                itemCount: imageList.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (BuildContext context, int index) {
                  bool isPreview = imageList.length == 1;
                  return Stack(
                    children: RectangleBoxList(isPreview, index),
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

class RectangleBox extends StatefulWidget {
  double mediaWidth;
  double width;
  double height;
  LottieText lottieText;
  int textDataMapIndex;
  var callback;

  RectangleBox({
    Key? key,
    required this.mediaWidth,
    required this.width,
    required this.height,
    required this.lottieText,
    required this.textDataMapIndex,
    required this.callback,
  }) : super(key: key);

  @override
  State<RectangleBox> createState() => _RectangleBoxState();
}

class _RectangleBoxState extends State<RectangleBox> {
  TextEditingController _textController = TextEditingController();

  var _timer;
  var _now;


  @override
  void initState() {
    super.initState();
    _textController.addListener(() {
      _now = DateTime.now();
      _timer = Timer(Duration(seconds: 1), () {
        int diff = _now.difference(DateTime.now()).inSeconds;
        if (diff <= -1) {
          if (_textController.text.isEmpty) {
          } else {
            widget.callback(widget.textDataMapIndex + 1, _textController);
          }
        }
      });

    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Rectangle rectangle = widget.lottieText.boundingBox;

    final mediaHeight = widget.height * widget.mediaWidth / widget.width;

    final x = widget.mediaWidth * rectangle.x / widget.width;
    final y = mediaHeight * rectangle.y / widget.height;

    final w = widget.mediaWidth * rectangle.width / widget.width;
    final h = mediaHeight * rectangle.height / widget.height;

    return Positioned(
        top: y,
        left: x,
        child: GestureDetector(
          onTap: () {
            print(
                'textDataMapIndex: ${widget.textDataMapIndex}, value : ${widget.lottieText.value}');
            _textController.text = widget.lottieText.value;
            showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(
                                bottom:
                                    MediaQuery.of(context).viewInsets.bottom),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _textController,
                                    autofocus: true,
                                    decoration: InputDecoration(
                                      hintText: "Please enter text",
                                      isDense: true,
                                      filled: true,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: Text("Close"),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 10),
                        ],
                      ),
                    ));
          },
          child: Container(
            width: w,
            height: h,
            color: Colors.grey.shade800.withOpacity(0.3),
          ),
        ));
  }
}
