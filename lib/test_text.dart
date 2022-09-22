import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/impl/vm_text_widget.dart';
import 'vm_sdk/impl/global_helper.dart';
import 'vm_sdk/impl/resource_manager.dart';
import 'vm_sdk/impl/ffmpeg_manager.dart';
import 'vm_sdk/types/types.dart';

class TestWidget extends StatefulWidget {
  TestWidget({Key? key}) : super(key: key);

  @override
  State<TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends State<TestWidget> {
  VMTextWidget _vmTextWidget = VMTextWidget();

  List<String> imageList = [];

  int _currentIndex = 0;
  bool _isRunning = false;

  bool _isInitialized = false;

  final FFMpegManager _ffmpegManager = FFMpegManager();

  void updateTextCallback(String key, String text) async {
    await _vmTextWidget.setTextValue(key, text);

    String? preview = _vmTextWidget.previewImagePath;
    setState(() {
      if (preview != null) imageList = [preview];
    });
  }

  void _run() async {
    try {
      if (!_isInitialized) {
        await ResourceManager.getInstance().loadResourceMap();
        _isInitialized = true;
      }

      setState(() {
        imageList = [];
      });

      final List<String> allTexts = ResourceManager.getInstance().getTextList(language: "en");

      // final String currentText =
      //     allTexts[(_currentIndex) % allTexts.length];

      // print('text is $currentText');
      // print('_currentIndex is $_currentIndex');

      // await _vmTextWidget.loadText(currentText);

      // String? preview = _vmTextWidget.previewImagePath;
      // setState(() {
      //   if (preview != null) imageList = [preview];
      // });

      // _currentIndex++;

      List<Map> list = [];

      Map excepts = {
      };

      for (int i = 0; i < allTexts.length; i++) {
        DateTime now = DateTime.now();

        final String currentText = allTexts[i];
        if (excepts.containsKey(currentText)) continue;

        print('text is $currentText');
        print('_currentIndex is $i / ${allTexts.length}');

        await _vmTextWidget.loadText(currentText, 2);
        await _vmTextWidget.extractAllSequence((progress) => {});      

        final String appDirPath = await getAppDirectoryPath();
        final String webmPath = "$appDirPath/webm";
        Directory dir = Directory(webmPath);
        await dir.create(recursive: true);

        String? preview = _vmTextWidget.previewImagePath;
        setState(() {
          if (preview != null) imageList = [preview];
        });

        int width = _vmTextWidget.width.floor();
        int height = _vmTextWidget.height.floor();

        width -= width % 2;
        height -= height % 2;

        await _ffmpegManager.execute([
          "-framerate",
          _vmTextWidget.frameRate.toString(),
          "-i",
          "${_vmTextWidget.allSequencesPath!}/%d.png",
          "-vf",
          "scale=$width:$height",
          "-c:v",
          "libvpx-vp9",
          "-pix_fmt",
          "yuva420p",
          "$webmPath/$currentText.webm",
          // "-c:v",
          // "libx264",
          // "-preset",
          // "ultrafast",
          // "-pix_fmt",
          // "yuv420p",
          // "$webmPath/$currentText.mp4",
          "-y"
        ], (p0) => null);

        File thumbnailFile = File(_vmTextWidget.previewImagePath!);
        await thumbnailFile.copy("$webmPath/$currentText.png");

        print(thumbnailFile.path);
        await Future.delayed(const Duration(seconds: 1));
      }

      print("");
    } catch (e) {
      print(e);
    } finally {
      // _isRunning = false;
    }
  }

  List<Widget> RectangleBoxList(isPreview, index) {
    VMTextWidget textWidget = _vmTextWidget;

    List<Widget> list = [];

    list.add(Container(
      child: Image.file(
        File(imageList[index]),
        width: MediaQuery.of(context).size.width,
        fit: BoxFit.fitWidth,
      ),
    ));

    if (isPreview) {
      for (final VMText vmText in _vmTextWidget.textDataMap.values) {
        list.add(RectangleBox(
          mediaWidth: MediaQuery.of(context).size.width,
          width: _vmTextWidget.width,
          height: _vmTextWidget.height,
          vmText: vmText,
          updateTextCallback: updateTextCallback,
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
              _vmTextWidget,
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
  VMText vmText;
  var updateTextCallback;

  RectangleBox({
    Key? key,
    required this.mediaWidth,
    required this.width,
    required this.height,
    required this.vmText,
    required this.updateTextCallback,
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
            widget.updateTextCallback(widget.vmText.key, _textController.text);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Rectangle rectangle = widget.vmText.boundingBox;

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
            _textController.text = widget.vmText.value;
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
