import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/text_box/painter/painter.dart';

class CanvasTextPainter extends CustomPainter {
  final TextBoxPainter painter;

  CanvasTextPainter({required this.painter});

  @override
  void paint(Canvas canvas, Size size) {
    painter.paint(canvas, size);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate != this;
  }
}