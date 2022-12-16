import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

class WrapTextPainter {
  final List<LineMetrics> lineMetrics;
  final Color borderColor;

  ///Capped to lineHeight*.3
  /// Any larger borderRadius will be ignored
  final double borderRadius;
  final EdgeInsets padding;
  final TextAlign textAlign;
  final double strokeWidth;
  final double margin;
  final double contentPadding;
  final PaintingStyle style;

  Radius radius = Radius.circular(0);

  WrapTextPainter({this.lineMetrics = const [],
    this.borderColor = Colors.black,
    this.strokeWidth = 5,
    this.borderRadius = 5,
    this.margin = 10,
    this.padding = const EdgeInsets.all(0),
    this.style = PaintingStyle.stroke,
    this.contentPadding = 0,
    this.textAlign = TextAlign.start}){
    radius = Radius.circular(borderRadius);
  }

  final _backgroundPath = Path();

  double get edgeMargin => strokeWidth + margin;

  void paint(Canvas canvas, Size size) {
    final _paint = Paint()
      ..color = borderColor
      ..strokeWidth = strokeWidth
      ..style = style;
    //final _defaultArcVal = radius.x < lineMetrics.first.height * 0.2 ? radius.x : lineMetrics.first.height * 0.2;
    final _defaultArcVal = radius.x;
    final _originLineMetric = LineMetrics(
        hardBreak: lineMetrics.first.hardBreak,
        height: 0,
        width: 0,
        left: size.width / 2,
        lineNumber: 0,
        ascent: lineMetrics.first.ascent,
        descent: lineMetrics.first.descent,
        baseline: lineMetrics.first.baseline,
        unscaledAscent: lineMetrics.first.unscaledAscent);
    final _endLineMetric = LineMetrics(
        hardBreak: lineMetrics.last.hardBreak,
        height: 0,
        width: 0,
        left: size.width / 2,
        lineNumber: 0,
        ascent: lineMetrics.last.ascent,
        descent: lineMetrics.last.descent,
        baseline: lineMetrics.last.baseline,
        unscaledAscent: lineMetrics.last.unscaledAscent);
    //Draw paths depending on the textAlign property
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        _drawRightPath(_defaultArcVal, _originLineMetric, _endLineMetric, size);
        canvas.drawPath(_backgroundPath, _paint);
        break;
      case TextAlign.right:
      case TextAlign.end:
        _drawLeftPath(_defaultArcVal, _originLineMetric, _endLineMetric, size);
        canvas.drawPath(_backgroundPath, _paint);
        break;
      case TextAlign.center:
        _drawLeftPath(_defaultArcVal, _originLineMetric, _endLineMetric, size);
        _drawRightPath(_defaultArcVal, _originLineMetric, _endLineMetric, size);
        canvas.drawPath(_backgroundPath, _paint);
        break;
      case TextAlign.justify:
        var rRect =
        RRect.fromLTRBR(-padding.left, -padding.top, size.width + padding.left, size.height + padding.top, radius);
        canvas.drawRRect(rRect, _paint);
        break;
    }
  }

  void _drawLeftPath(double _defaultArcVal, LineMetrics _originLineMetric, LineMetrics _endLineMetric,
      Size widgetSize) {
    //Draw left Path, start is middle top, end is middle bottom
    for (var i = 0; i < lineMetrics.length; i++) {
      final lineMetric = lineMetrics[i];
      var width = max(lineMetric.width, 5);
      double? lineMetricHeight;
      double? lastTopY;
      double? lastBottomY;
      lineMetricHeight = lineMetricHeight != null
          ? min(lineMetricHeight, lineMetric.height + contentPadding)
          : lineMetric.height + contentPadding;
      final _leftX = lineMetric.left - padding.left;
      final _lineTopY = lineMetricHeight * lineMetric.lineNumber - (i == 0 ? padding.top : 0) + edgeMargin;
      final _lineBottomY =
          lineMetricHeight * (lineMetric.lineNumber + 1) + (i == lineMetrics.length - 1 ? padding.bottom : 0);
      if (!(i == lineMetrics.length - 1 && lineMetric.width == 0)) {
        final _previousLine = i != 0 ? lineMetrics[i - 1] : _originLineMetric;
        final _nextLine = i != lineMetrics.length - 1 ? lineMetrics[i + 1] : _endLineMetric;

        final _isTopArcClockWise = width < _previousLine.width;
        final _isBottomArcClockWise = width < _nextLine.width;

        final _arcTopOffset = _getArcTopValues(_isTopArcClockWise, _previousLine, lineMetric, _defaultArcVal);
        final _arcBottomOffset = _getArcBottomValues(_isBottomArcClockWise, _nextLine, lineMetric, _defaultArcVal);

        final _arcTopY = _arcTopOffset.dy;
        final _arcTopX = _arcTopOffset.dx;

        final _arcBottomY = _arcBottomOffset.dy;
        final _arcBottomX = _arcBottomOffset.dx;

        if (i == 0) {
          _moveToOriginPath(widgetSize, _defaultArcVal, _lineTopY);
        }

        _backgroundPath.lineTo(_leftX - _arcTopY + _arcTopX + margin, _lineTopY - (i == 0 ? 0 : margin));
        _backgroundPath.arcToPoint(Offset(_leftX + margin, _lineTopY + _arcTopY + _arcTopX - (i == 0 ? 0 : margin)),
            radius: radius, clockwise: _isTopArcClockWise);
        _backgroundPath.lineTo(_leftX + margin, _lineBottomY - _arcBottomY - _arcBottomX + strokeWidth);
        _backgroundPath.arcToPoint(Offset(_leftX - _arcBottomY + _arcBottomX + margin, _lineBottomY + strokeWidth),
            radius: radius, clockwise: _isBottomArcClockWise);
      }
      if (i == lineMetrics.length - 1) {
        if (lineMetric.width != 0) {
          _drawFinishPath(widgetSize, _defaultArcVal, _lineTopY, _lineBottomY);
        } else if (lastTopY != null && lastBottomY != null) {
          _drawFinishPath(widgetSize, _defaultArcVal, lastTopY, lastBottomY);
        }

        lastTopY = _lineTopY;
        lastBottomY = _lineBottomY;
      }
    }
  }

  void _drawRightPath(double _defaultArcVal, LineMetrics _originLineMetric, LineMetrics _endLineMetric,
      Size widgetSize) {
    //Draw left Path, start is middle top, end is middle bottom
    double? lineMetricHeight;
    double? lastTopY;
    double? lastBottomY;
    for (var i = 0; i < lineMetrics.length; i++) {
      final lineMetric = lineMetrics[i];
      var width = max(lineMetric.width, 5);
      lineMetricHeight = lineMetricHeight != null
          ? min(lineMetricHeight, lineMetric.height + contentPadding)
          : lineMetric.height + contentPadding;
      radius = Radius.circular(min(borderRadius, 10));
      final _rightX = lineMetric.left + width + padding.left;
      final _lineTopY = lineMetricHeight * lineMetric.lineNumber - (i == 0 ? padding.top : 0) + edgeMargin;
      final _lineBottomY =
          lineMetricHeight * (lineMetric.lineNumber + 1) + (i == lineMetrics.length - 1 ? padding.bottom : 0);
      if (!(i == lineMetrics.length - 1 && lineMetric.width == 0)) {
        final _previousLine = i != 0 ? lineMetrics[i - 1] : _originLineMetric;
        final _nextLine = i != lineMetrics.length - 1 ? lineMetrics[i + 1] : _endLineMetric;

        final _isTopArcClockWise = width > _previousLine.width;
        final _isBottomArcClockWise = width > _nextLine.width;

        final _arcTopOffset = _getArcTopValues(_isTopArcClockWise, lineMetric, _previousLine, _defaultArcVal);
        final _arcBottomOffset = _getArcBottomValues(_isBottomArcClockWise, lineMetric, _nextLine, _defaultArcVal);
        //print('_arcTopOffset - $_arcTopOffset');
        final _arcTopY = _arcTopOffset.dy;
        final _arcTopX = _arcTopOffset.dx;
        final _arcBottomY = _arcBottomOffset.dy;
        final _arcBottomX = _arcBottomOffset.dx;

        if (i == 0) {
          _moveToOriginPath(widgetSize, _defaultArcVal, _lineTopY);
        }

        _backgroundPath.lineTo(_rightX - _arcTopY + _arcTopX, _lineTopY - (i == 0 ? 0 : margin));
        _backgroundPath.arcToPoint(Offset(_rightX, _lineTopY + _arcTopY + _arcTopX - (i == 0 ? 0 : margin)),
            radius: radius, clockwise: _isTopArcClockWise);
        _backgroundPath.lineTo(_rightX, _lineBottomY - _arcBottomY - _arcBottomX + strokeWidth);
        _backgroundPath.arcToPoint(Offset(_rightX - _arcBottomY + _arcBottomX, _lineBottomY + strokeWidth),
            radius: radius, clockwise: _isBottomArcClockWise);
      }
      if (i == lineMetrics.length - 1) {
        if (lineMetric.width != 0) {
          _drawFinishPath(widgetSize, _defaultArcVal, _lineTopY, _lineBottomY);
        } else if (lastTopY != null && lastBottomY != null) {
          _drawFinishPath(widgetSize, _defaultArcVal, lastTopY, lastBottomY);
        }
      }
      lastTopY = _lineTopY;
      lastBottomY = _lineBottomY;
    }
  }

  Offset _getArcTopValues(bool _isTopArcClockWise, LineMetrics firstLineMetric, LineMetrics secondLineMetric,
      double _defaultArcVal) {
    var _arcTopX = 0.0;
    var _arcTopY = 0.0;
    var firstMetricWidth = max(firstLineMetric.width, 10);
    var secondMetricWidth = max(secondLineMetric.width, 10);

    if (_isTopArcClockWise) {
      final _currentToPreviousLineDifference = (firstMetricWidth - secondMetricWidth) / 2;
      final isTopLineSmallerAsDefaultArc = _defaultArcVal > _currentToPreviousLineDifference;
      if (isTopLineSmallerAsDefaultArc) {
        _arcTopY = _currentToPreviousLineDifference / 2;
      } else {
        _arcTopY = _defaultArcVal;
      }
      _arcTopX = 0;
    } else {
      final _previousToCurrentLineDifference = (secondMetricWidth - firstMetricWidth) / 2;
      final isTopLineSmallerAsDefaultArc = _defaultArcVal > _previousToCurrentLineDifference;
      if (isTopLineSmallerAsDefaultArc) {
        _arcTopX = _previousToCurrentLineDifference / 2;
      } else {
        _arcTopX = _defaultArcVal;
      }
      _arcTopY = 0;
    }

    return Offset(_arcTopX, _arcTopY);
  }

  Offset _getArcBottomValues(bool _isBottomArcClockWise, LineMetrics firstLineMetric, LineMetrics secondLineMetric,
      double _defaultArcVal) {
    var _arcBottomY = 0.0;
    var _arcBottomX = 0.0;
    var firstMetricWidth = max(firstLineMetric.width, 10);
    var secondMetricWidth = max(secondLineMetric.width, 10);
    if (_isBottomArcClockWise) {
      final _currentToNextLineDifference = (firstMetricWidth - secondMetricWidth) / 2;
      final isBottomLineSmallerAsDefaultArc = _defaultArcVal > _currentToNextLineDifference;
      if (isBottomLineSmallerAsDefaultArc) {
        _arcBottomY = _currentToNextLineDifference / 2;
      } else {
        _arcBottomY = _defaultArcVal;
      }
      _arcBottomX = 0;
    } else {
      final _currentToNextLineDifference = (secondMetricWidth - firstMetricWidth) / 2;
      final isBottomLineSmallerAsDefaultArc = _defaultArcVal > _currentToNextLineDifference;
      if (isBottomLineSmallerAsDefaultArc) {
        _arcBottomX = _currentToNextLineDifference / 2;
      } else {
        _arcBottomX = _defaultArcVal;
      }
      _arcBottomY = 0;
    }

    return Offset(_arcBottomX, _arcBottomY);
  }

  void _moveToOriginPath(Size widgetSize, double _defaultArcVal, double _lineTopY) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        _backgroundPath.moveTo(_defaultArcVal + strokeWidth, _lineTopY);
        break;
      case TextAlign.right:
      case TextAlign.end:
        _backgroundPath.moveTo(widgetSize.width - _defaultArcVal, _lineTopY);
        break;
      case TextAlign.center:
        _backgroundPath.moveTo(widgetSize.width / 2, _lineTopY);
        break;
      case TextAlign.justify:
        break;
    }
  }

  void _drawFinishPath(Size widgetSize, double _defaultArcVal, double _lineTopY, double _lineBottomY) {
    switch (textAlign) {
      case TextAlign.left:
      case TextAlign.start:
        _backgroundPath.lineTo(_defaultArcVal - padding.left + margin, _lineBottomY + strokeWidth);
        _backgroundPath.arcToPoint(Offset(-padding.left + margin, _lineBottomY - _defaultArcVal + strokeWidth),
            radius: radius, clockwise: true);
        _backgroundPath.lineTo(-padding.left + margin, _defaultArcVal - padding.top + edgeMargin);
        //_backgroundPath.arcToPoint(Offset(-padding.left + _defaultArcVal + strokeWidth, -padding.top),
        _backgroundPath.arcToPoint(Offset(-padding.left + _defaultArcVal + margin, -padding.top + edgeMargin),
            radius: radius, clockwise: true);
        _backgroundPath.close();
        break;
      case TextAlign.right:
      case TextAlign.end:
        _backgroundPath.lineTo(widgetSize.width + padding.right - _defaultArcVal - margin, _lineBottomY + strokeWidth);
        _backgroundPath.arcToPoint(
            Offset(widgetSize.width + padding.right - margin, _lineBottomY - _defaultArcVal + strokeWidth),
            radius: radius,
            clockwise: false);
        _backgroundPath.lineTo(widgetSize.width + padding.right - margin, _defaultArcVal - padding.top + edgeMargin);
        _backgroundPath.arcToPoint(
            Offset(widgetSize.width + padding.right - _defaultArcVal - margin, -padding.top + edgeMargin),
            radius: radius,
            clockwise: false);
        _backgroundPath.close();
        break;
      case TextAlign.center:
        _backgroundPath.lineTo(widgetSize.width / 2, _lineBottomY + strokeWidth);
        break;
      case TextAlign.justify:
        break;
    }
  }

}
