import 'dart:math';
import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/text_box/text_box_wrap_type.dart';
import 'package:network_font/network_font.dart';
import 'emoji_text_span.dart';
import 'text/config.dart';

class TextBoxPainter {
  final CanvasTextConfig config;
  final EdgeInsets boxPadding;
  final NetworkFont font = NetworkFont('Roboto', url: '');

  TextBoxPainter({required this.config, required this.boxPadding});

  double sidePadding = 10;
  double lineMetricGapRatio = 1.0;

  TextStyle get foreGroundStl => TextStyle(
    color: config.textColor,
    fontWeight: FontWeight.w600,
    fontSize: config.fontSize,
    letterSpacing: config.letterSpacing,
    height: config.textHeight + (config.borderWidth / config.fontSize),
  ).network(config.font ?? font);

  TextStyle get outLineStl => TextStyle(
    fontWeight: FontWeight.w600,
    fontSize: config.fontSize,
    letterSpacing: config.letterSpacing,
    height: config.textHeight + (config.borderWidth / config.fontSize),
    foreground: Paint()
      ..color = config.outlineColor != null && config.outlineWidth > 0 ? config.outlineColor! : Colors.transparent
      ..strokeWidth = config.outlineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke,
    shadows: config.shadowRadius > 0.0
        ? [
      Shadow(
        blurRadius: config.shadowRadius,
        offset: Offset(cos(config.shadowAngle * pi * 2) * config.shadowDistance,
            sin(config.shadowAngle * pi * 2) * config.shadowDistance),
        color: config.textShadow,
      )
    ]
        : null,
  ).network(config.font ?? font);

  Rect paint(Canvas canvas, Size size) {
    return drawTextDynamically(canvas, config.text);
  }

  Rect drawTextDynamically(Canvas canvas, String text) {
    String text = 'Input text';
    Rect rect;
    if (config.text.isNotEmpty) {
      text = config.text;
    }
    List<String> texts = text.split('\n');
    if (texts.isEmpty) {
      texts = [text];
    }
    double basePadding = (config.textHeight - 1.0) * config.fontSize;
    double fullPadding = basePadding * 2;
    double maxTextWidth = 0;
    List<TextPainter> textPainters = [];
    for (int i = 0; i < texts.length; i++) {
      String str = texts[i];

      final foregroundTextSpan = EmojiTextSpan(
        text: str,
        style: foreGroundStl,
      );
      final foregroundTextPainter = TextPainter(
        text: foregroundTextSpan,
        textDirection: TextDirection.ltr,
        textAlign: config.textAlign,
      );
      foregroundTextPainter.layout(
        minWidth: 40,
      );
      if (foregroundTextPainter.width > maxTextWidth) {
        maxTextWidth = foregroundTextPainter.width;
      }
      textPainters.add(foregroundTextPainter);
    }

    Path _path = Path();
    if (config.textBoxWrapType == TextBoxWrapType.wrapLine) {
      if (config.textAlign == TextAlign.center) {
        drawHalfCenter(_path, textPainters, basePadding, fullPadding, maxTextWidth);
        _path = _path.transform(Matrix4.rotationY(pi).storage);
        _path = _path.transform(
            Matrix4.translationValues(maxTextWidth + fullPadding + config.borderWidth + sidePadding * 2, 0, 0).storage);
        drawHalfCenter(_path, textPainters, basePadding, fullPadding, maxTextWidth);
      } else {
        drawStart(_path, textPainters, basePadding, fullPadding);

        if (config.textAlign == TextAlign.end) {
          _path = _path.transform(Matrix4.rotationY(pi).storage);
          _path =
              _path.transform(Matrix4.translationValues(maxTextWidth + fullPadding + sidePadding * 2, 0, 0).storage);
        }
      }
      canvas.drawPath(_path, Paint()..color = config.fillColor);
      rect = Rect.fromLTWH(0, 0, _path.getBounds().width + (sidePadding * 2) + boxPadding.left,
          _path.getBounds().height + boxPadding.bottom + boxPadding.top);
      for (int i = 0; i < textPainters.length; i++) {
        var painter = textPainters[i];
        String str = texts[i];
        final primaryTextSpan = EmojiTextSpan(
          text: str,
          style: outLineStl,
        );
        final primaryTextPainter = TextPainter(
          text: primaryTextSpan,
          textDirection: TextDirection.ltr,
          textAlign: config.textAlign,
        );
        primaryTextPainter.layout(
          minWidth: 40,
        );
        drawTextPainter(canvas, primaryTextPainter, basePadding, maxTextWidth, i, textPainters.length);
        //}
        drawTextPainter(canvas, painter, basePadding, maxTextWidth, i, textPainters.length);
      }

      ///UNCOMMENT IF YOU WANT BORDER WIDTH BACK
      // canvas.drawPath(_path, Paint()
      //   ..color = config.borderColor
      //   ..strokeWidth = config.borderWidth
      //   ..style = PaintingStyle.stroke);
    } else {
      if (textPainters.isNotEmpty) {
        final radius = config.borderRadius;
        final rad = Radius.circular(radius);
        const edge = -1.0;
        final tHeight = textPainters[0].height + basePadding;
        _path.moveTo(radius + edge, edge);
        _path.lineTo(maxTextWidth + fullPadding - radius, edge);
        _path.arcToPoint(Offset(maxTextWidth + fullPadding, edge + radius), radius: rad, clockwise: true);
        _path.lineTo(maxTextWidth + fullPadding, edge + (tHeight * textPainters.length) - radius);
        _path.arcToPoint(Offset(maxTextWidth + fullPadding - radius, edge + (tHeight * textPainters.length)),
            radius: rad, clockwise: true);
        _path.lineTo(edge + radius, edge + (tHeight * textPainters.length));
        _path.arcToPoint(Offset(edge, edge + (tHeight * textPainters.length) - radius), radius: rad, clockwise: true);
        _path.lineTo(edge, edge + radius);
        _path.arcToPoint(Offset(radius + edge, edge), radius: rad, clockwise: true);
        canvas.drawPath(
            _path,
            Paint()
              ..color = config.fillColor
              ..style = PaintingStyle.fill);
      }
      for (int i = 0; i < textPainters.length; i++) {
        var painter = textPainters[i];
        if (config.outlineColor != null && config.outlineColor != Colors.transparent && config.outlineWidth > 0) {
          String str = texts[i];
          final primaryTextSpan = TextSpan(
            text: str,
            style: outLineStl,
          );
          final primaryTextPainter = TextPainter(
            text: primaryTextSpan,
            textDirection: TextDirection.ltr,
            textAlign: config.textAlign,
          );
          primaryTextPainter.layout(
            minWidth: 40,
          );
          drawTextPainter(canvas, primaryTextPainter, basePadding, maxTextWidth, i, textPainters.length);
        }
        drawTextPainter(canvas, painter, basePadding, maxTextWidth, i, textPainters.length);
      }
      rect = Rect.fromLTWH(0, 0, _path.getBounds().width + (sidePadding * 2) + boxPadding.left + boxPadding.right,
          _path.getBounds().height + boxPadding.bottom);
    }
    return rect;
  }

  void drawTextPainter(Canvas canvas, TextPainter painter, double basePadding, double maxTextWidth, int i, length) {
    double lineHeight = config.fontSize + basePadding;
    Offset? offset;
    if (config.textAlign == TextAlign.start) {
      offset = Offset(
          basePadding + sidePadding,
          (lineHeight + basePadding + config.borderWidth) * i +
              (basePadding / 2) -
              (config.borderWidth / length) +
              sidePadding);
    } else if (config.textAlign == TextAlign.center) {
      double gapByCenterW = maxTextWidth == painter.width ? 0 : (maxTextWidth - painter.width) / 2;
      offset = Offset(
          basePadding + gapByCenterW + config.borderWidth + sidePadding,
          (lineHeight + basePadding + config.borderWidth) * i +
              (basePadding / 2) -
              (config.borderWidth / length) +
              sidePadding);
    } else if (config.textAlign == TextAlign.end) {
      offset = Offset(
          maxTextWidth - painter.width + basePadding + sidePadding,
          (lineHeight + basePadding + config.borderWidth) * i +
              (basePadding / 2) -
              (config.borderWidth / length) +
              sidePadding);
    }
    painter.paint(canvas, offset!);
  }

  void drawStart(Path _path, List<TextPainter> textPainters, double basePadding, double fullPadding) {
    for (int i = 0; i < textPainters.length; i++) {
      TextPainter? previous = i > 0 ? textPainters[i - 1] : null;
      final painter = textPainters[i];
      final textW = painter.width;
      final textH = painter.height;
      final radius = config.borderRadius;
      final rad = Radius.circular(radius);
      final edge = config.borderWidth;
      final heightByLines = (i == 0 ? edge : edge + (textH + basePadding) * i) + sidePadding;
      final heightByNextLine = (textH + basePadding) * (i + 1) + sidePadding;

      TextPainter? next = (i + 1) < textPainters.length ? textPainters[i + 1] : null;
      double? nextWidth = next?.width;
      final first = i == 0;
      final last = (i + 1) == textPainters.length;
      final minLeft = edge + sidePadding;
      if (first) {
        _path.moveTo(radius + minLeft, heightByLines);
      }
      if (previous == null) {
        _path.lineTo(textW + fullPadding - radius + sidePadding, heightByLines);
        _path.arcToPoint(Offset(textW + fullPadding + sidePadding, heightByLines + radius),
            radius: rad, clockwise: true);
      } else {
        //_path.lineTo(textW + (basePadding * 2) - radius, heightByLines);
        //_path.arcToPoint(Offset(textW + basePadding, heightByLines + radius), radius: rad, clockwise: true);
      }
      if (next != null) {
        if (nextWidth! > textW) {
          final gap = nextWidth - textW;
          double radT = radius;
          if (gap < (radius * 2)) {
            radT = gap / 2;
          }
          _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radT);

          _path.arcToPoint(Offset(textW + fullPadding + radT + sidePadding, heightByNextLine),
              radius: Radius.circular(radT), clockwise: false);
          _path.lineTo(nextWidth + fullPadding - radT + sidePadding, heightByNextLine);
          _path.arcToPoint(Offset(nextWidth + fullPadding + sidePadding, heightByNextLine + radT),
              radius: Radius.circular(radT), clockwise: nextWidth > textW);
        } else {
          final gap = (painter.width - next.width) / 2;
          double radT = radius;
          if (gap < (radius * 2)) {
            radT = min(radius, gap);
          }
          _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radT);
          //_path.lineTo(textW + basePadding, heightByNextLine);
          _path.arcToPoint(Offset(textW + fullPadding - radT + sidePadding, heightByNextLine),
              radius: Radius.circular(radT), clockwise: true);
          _path.lineTo(nextWidth + fullPadding + radT + sidePadding, heightByNextLine);
          _path.arcToPoint(Offset(nextWidth + fullPadding + sidePadding, heightByNextLine + radT),
              radius: Radius.circular(radT), clockwise: false);
        }
        //_path.arcToPoint(Offset(nextWidth + fullPadding, heightByNextLine + radius), radius: rad, clockwise: closeWise);
        //_path.quadraticBezierTo(textW + fullPadding, heightByLines - radius, next.width + fullPadding, heightByLines);
      } else {
        _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radius);

        final nextX = textW + fullPadding - radius + sidePadding;
        _path.arcToPoint(Offset(nextX, heightByNextLine), radius: rad, clockwise: true);
      }

      if (last) {
        _path.lineTo(radius + edge + sidePadding, heightByNextLine);
        _path.arcToPoint(Offset(edge + sidePadding, heightByNextLine - radius), radius: rad, clockwise: true);
        _path.lineTo(edge + sidePadding, radius + edge + sidePadding);
        _path.arcToPoint(Offset(radius + edge + sidePadding, edge + sidePadding), radius: rad, clockwise: true);
        _path.close();
      }
    }
  }

  void drawHalfCenter(
      Path _path, List<TextPainter> textPainters, double basePadding, double fullPadding, double maxTextWidth) {
    for (int i = 0; i < textPainters.length; i++) {
      TextPainter? previous = i > 0 ? textPainters[i - 1] : null;
      final painter = textPainters[i];
      final edge = config.borderWidth;
      double gapByCenterW = maxTextWidth == painter.width ? 0 : (maxTextWidth - painter.width) / 2;
      final textW = gapByCenterW + painter.width;
      final textH = painter.height;
      final radius = config.borderRadius;
      final rad = Radius.circular(radius);
      final heightByLines = (textH + basePadding) * i + sidePadding;
      final heightByNextLine = (textH + basePadding) * (i + 1) + sidePadding;

      TextPainter? next = (i + 1) < textPainters.length ? textPainters[i + 1] : null;
      double? nextWidth;
      if (next != null) {
        final gapByNextCenterW = maxTextWidth == next.width ? 0 : (maxTextWidth - next.width) / 2;
        nextWidth = gapByNextCenterW + next.width;
      }
      final first = i == 0;
      final last = (i + 1) == textPainters.length;
      if (first) {
        _path.moveTo(gapByCenterW + (painter.width / 2) + basePadding + sidePadding, heightByLines + edge);
      }
      if (previous == null) {
        _path.lineTo(textW + fullPadding - radius + sidePadding, heightByLines + edge);
        _path.arcToPoint(Offset(textW + fullPadding + sidePadding, heightByLines + radius),
            radius: rad, clockwise: true);
      } else {
        //_path.lineTo(textW + (basePadding * 2) - radius, heightByLines);
        //_path.arcToPoint(Offset(textW + basePadding, heightByLines + radius), radius: rad, clockwise: true);
      }
      if (next != null) {
        if (nextWidth! > textW) {
          final gap = nextWidth - textW;
          double radT = radius;
          if (gap < (radius * 2)) {
            radT = gap / 2;
          }
          _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radT);

          _path.arcToPoint(Offset(textW + fullPadding + radT + sidePadding, heightByNextLine),
              radius: Radius.circular(radT), clockwise: false);
          _path.lineTo(nextWidth + fullPadding - radT + sidePadding, heightByNextLine);
          _path.arcToPoint(Offset(nextWidth + fullPadding + sidePadding, heightByNextLine + radT),
              radius: Radius.circular(radT), clockwise: nextWidth > textW);
        } else {
          final gap = (painter.width - next.width) / 2;
          double radT = radius;
          if (gap < (radius * 2)) {
            radT = min(radius, gap);
          }
          _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radT);
          _path.arcToPoint(Offset(textW + fullPadding - radT + sidePadding, heightByNextLine),
              radius: Radius.circular(radT), clockwise: true);
          _path.lineTo(nextWidth + fullPadding + radT + sidePadding, heightByNextLine);
          _path.arcToPoint(Offset(nextWidth + fullPadding + sidePadding, heightByNextLine + radT),
              radius: Radius.circular(radT), clockwise: false);
        }
      } else {
        _path.lineTo(textW + fullPadding + sidePadding, heightByNextLine - radius);

        final nextX = textW + fullPadding - radius + sidePadding;
        _path.arcToPoint(Offset(nextX, heightByNextLine), radius: rad, clockwise: true);
      }

      if (last) {
        _path.lineTo(gapByCenterW + (painter.width / 2) + basePadding + sidePadding, heightByNextLine);
        //_path.arcToPoint(Offset(edge + sidePadding, heightByNextLine - radius), radius: rad, clockwise: true);
      }
    }
  }
}
