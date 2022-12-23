import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:myapp/vm_sdk/text_box/painter/painter.dart';
import 'package:myapp/vm_sdk/text_box/text/config.dart';
import 'package:path_provider/path_provider.dart';
import 'helper/debouncer.dart';

class TextBoxConfigController {
  final CanvasTextConfig? initialConfig;
  CanvasTextConfig? _currentConfig;
  final EdgeInsets padding;
  final String label;
  static String subPath = '/Documents/VIIV/captions';
  double? Function()? scaleSetter;

  CanvasTextConfig? get config => _currentConfig;
  Directory? appPath;
  Size? _size;
  Size get size => _size ?? Size.zero;
  Function(Size size)? onSizeUpdate;

  Completer<String>? _saveCompleter;

  Debouncer debouncer = Debouncer(delay: Duration(milliseconds: 100));

  TextBoxConfigController(this.label,
      {required this.padding, this.initialConfig, this.onSizeUpdate, this.scaleSetter}) {
    _currentConfig = initialConfig;
  }

  void updateConfig(CanvasTextConfig config) {
    _currentConfig = config;
    debouncer.call(() {
      renderImageAndSave();
    });
  }

  TextBoxPainter? get painter => config != null ? TextBoxPainter(config: config!, boxPadding: padding) : null;

  Future<String> renderImageAndSave() async {
    _saveCompleter = Completer();
    try {
      if (painter != null) {
        final ui.PictureRecorder recorder = ui.PictureRecorder();
        appPath ??= await getApplicationDocumentsDirectory();
        Rect newSize;
        Size? mSize;
        Canvas canvas = Canvas(recorder);
        double ratio = mSize != null ? 1080 / mSize.width : 1;
        Size imageSize;
        print('mSize - $mSize');
        if (mSize != null) {
          imageSize = Size(mSize.width * ratio, mSize.height * ratio);
          canvas.save();
          canvas.scale(ratio);
          newSize = painter!.paint(canvas, Size.infinite);
        } else {
          newSize = painter!.paint(canvas, Size.infinite);

          imageSize = newSize.size;
          canvas.save();
          canvas.scale(ratio);
        }

        print('newSize - $newSize');
        canvas.restore();

        var outerSize = Size(
            newSize.size.width, newSize.size.height + ((padding.top + padding.bottom) / (scaleSetter?.call() ?? 1.0)));
        updateSize(outerSize);
        debouncer.call(() async {
          try {
            ui.Image renderedImage =
            await recorder.endRecording().toImage(imageSize.width.floor(), imageSize.height.floor());

            var pngBytes = await renderedImage.toByteData(format: ui.ImageByteFormat.png);

            File saveFile = File('${appPath!.path}$subPath/${DateTime.now().millisecondsSinceEpoch}.png');

            if (!(await saveFile.exists())) {
              await saveFile.create(recursive: true);
            }
            await saveFile.writeAsBytes(pngBytes!.buffer.asUint8List(), flush: true);

            if (_saveCompleter != null) {
              _saveCompleter!.complete(saveFile.path);
            }
          }
          catch (e) {
            if (_saveCompleter != null) {
              _saveCompleter!.completeError(e);
            }
          }
        });
      }
    }
    catch (e) {
      if (_saveCompleter != null) {
        _saveCompleter!.completeError(e);
      }
    }
    return _saveCompleter!.future;
  }

  void updateSize(Size size){
    _size = size;
    onSizeUpdate?.call(size);
  }
}