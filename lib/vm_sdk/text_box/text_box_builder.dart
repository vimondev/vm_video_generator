import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/text_box/painter/painter.dart';
import 'package:myapp/vm_sdk/text_box/text/config.dart';
import 'package:myapp/vm_sdk/text_box/text_box_config_controller.dart';

import 'canvas_painter.dart';

class TextBoxBuilder extends StatefulWidget {
  final TextBoxConfigController controller;
  final CanvasTextConfig? config;

  const TextBoxBuilder({Key? key, required this.controller, this.config}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TextBoxBuilderState();
}

class _TextBoxBuilderState extends State<TextBoxBuilder> {
  CanvasTextConfig? _config;

  final double horPad = 10;

  final double verPad = 10;

  EdgeInsets get padding => EdgeInsets.symmetric(horizontal: horPad, vertical: verPad);

  TextBoxPainter? painter;

  @override
  void didUpdateWidget(covariant TextBoxBuilder oldWidget) {
    if (widget.config != null && _config != widget.config) {
      _config = widget.config;
      widget.controller.updateConfig(_config!);
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void initState() {
    super.initState();
    _config = widget.config;
    if (_config != null) {
      widget.controller.updateConfig(_config!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      Widget childWidget = Container();
      if (_config != null) {
        painter = TextBoxPainter(config: _config!, boxPadding: padding);
        childWidget = SizedBox(
          width: widget.controller.size.width,
          height: widget.controller.size.height,
          child: CustomPaint(
            painter: CanvasTextPainter(painter: painter!),
          ),
        );
      } else {
        childWidget = const SizedBox.shrink();
      }

      return SizedBox(
          height: widget.controller.size.height,
          width: widget.controller.size.width,
          child: Center(child: childWidget));
    });
  }
}
