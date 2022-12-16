import 'dart:math';

import 'package:flutter/material.dart';
import 'package:network_font/network_font.dart';
import '../text_box_wrap_type.dart';
import 'base_text_config.dart';

class CanvasTextConfig extends BaseTextConfig {
  final FontWeight fontWeight;
  final Color fillColor;
  final Color textColor;
  final Color? outlineColor;
  final Color borderColor;
  final double borderWidth;
  final TextAlign textAlign;
  final TextDecoration textDecoration;
  final NetworkFont? font;
  final double fontSize;
  final double borderRadius;
  final double contentPadding;
  final Color textShadow;
  final double shadowRadius;
  final double textHeight;
  final double letterSpacing;
  final Color? borderShadow;
  final double outlineWidth;
  final double shadowAngle;
  final double shadowDistance;
  final bool isDisableOutline;
  final bool isDisableShadow;
  final bool isDisableBackground;
  final TextBoxWrapType textBoxWrapType;

  CanvasTextConfig(
      {required String text,
      this.textAlign = TextAlign.center,
      this.fillColor = Colors.black,
      this.textColor = Colors.white,
      this.borderColor = Colors.white,
      this.textBoxWrapType = TextBoxWrapType.wrapLine,
      this.shadowDistance = 1.0,
      this.shadowAngle = (pi / 4) / (pi * 2),
      this.textHeight = 1.2,
      this.letterSpacing = 0.3,
      this.outlineWidth = 0,
      this.font,
      this.outlineColor,
      this.borderWidth = 0.0,
      this.borderRadius = 3,
      this.fontWeight = FontWeight.w500,
      this.fontSize = 15,
      this.contentPadding = 16,
      this.textShadow = Colors.transparent,
      this.shadowRadius = 1.0,
      this.borderShadow,
      this.textDecoration = TextDecoration.none,
      this.isDisableOutline = false,
      this.isDisableShadow = false,
      this.isDisableBackground = false})
      : super(text);

  factory CanvasTextConfig.fromMap(Map<String, dynamic> map) {
    TextAlign textAlign;
    FontWeight fontWeight;
    TextBoxWrapType textBoxWrapType;
    switch (map['fontWeight'].toString()) {
      case 'light':
        fontWeight = FontWeight.w300;
        break;
      case 'normal':
        fontWeight = FontWeight.normal;
        break;
      case 'medium':
        fontWeight = FontWeight.w600;
        break;
      case 'bold':
        fontWeight = FontWeight.w700;
        break;
      default:
        fontWeight = FontWeight.normal;
    }
    switch (map['textBoxWrapType'].toString()) {
      case 'wrapLine':
        textBoxWrapType = TextBoxWrapType.wrapLine;
        break;
      case 'wrapBox':
        textBoxWrapType = TextBoxWrapType.wrapBox;
        break;
      default:
        textBoxWrapType = TextBoxWrapType.wrapLine;
    }
    switch (map['textAlign'].toString()) {
      case 'start':
        textAlign = TextAlign.start;
        break;
      case 'center':
        textAlign = TextAlign.center;
        break;
      case 'justify':
        textAlign = TextAlign.justify;
        break;
      case 'end':
        textAlign = TextAlign.end;
        break;
      default:
        textAlign = TextAlign.center;
    }
    TextDecoration textDecoration;
    switch (map['textDecoration'].toString()) {
      case 'none':
        textDecoration = TextDecoration.none;
        break;
      case 'underline':
        textDecoration = TextDecoration.underline;
        break;
      case 'overline':
        textDecoration = TextDecoration.overline;
        break;
      case 'lineThrough':
        textDecoration = TextDecoration.lineThrough;
        break;
      default:
        textDecoration = TextDecoration.none;
    }
    return CanvasTextConfig(
        text: map['text'] ?? '',
        fillColor: map['fillColor'] != null && map['fillColor'] is int ? Color(map['fillColor']) : Colors.transparent,
        textColor: map['textColor'] != null && map['textColor'] is int ? Color(map['textColor']) : Colors.black,
        borderColor: map['borderColor'] != null && map['borderColor'] is int ? Color(map['borderColor']) : Colors.black,
        borderWidth: parseDouble(map['borderWidth']) ?? 1.0,
        contentPadding: parseDouble(map['contentPadding']) ?? 5.0,
        fontSize: parseDouble(map['fontSize']) ?? 20.0,
        textAlign: textAlign,
        font: map['font']?['fontFamily'] != null
            ? NetworkFont(map['font']?['fontFamily'], url: map['font']?['url'])
            : null,
        borderShadow: map['borderShadow'] != null && map['borderShadow'] is int ? Color(map['borderShadow']) : null,
        textDecoration: textDecoration,
        shadowRadius: parseDouble(map['shadowRadius']) ?? 0.0,
        textHeight: parseDouble(map['textHeight']) ?? 1.0,
        fontWeight: fontWeight,
        borderRadius: parseDouble(map['borderRadius']) ?? 2.0,
        letterSpacing: parseDouble(map['letterSpacing']) ?? 2.0,
        shadowDistance: parseDouble(map['shadowDistance']) ?? 1.0,
        shadowAngle: parseDouble(map['shadowAngle']) ?? 0.0,
        textShadow:
            map['textShadow'] != null && map['textShadow'] is int ? Color(map['textShadow']) : Colors.transparent,
        outlineColor:
            map['outlineColor'] != null && map['outlineColor'] is int ? Color(map['outlineColor']) : Colors.black,
        outlineWidth: parseDouble(map['outlineWidth']) ?? 0.0,
        isDisableOutline: map['isDisableOutline'] ?? false,
        isDisableShadow: map['isDisableShadow'] ?? false,
        textBoxWrapType: textBoxWrapType,
        isDisableBackground: map['isDisableBackground'] ?? false);
  }

  TextAlign textAlignFromString(String? value) {
    switch (value) {
      case 'start':
        return TextAlign.start;
      case 'center':
        return TextAlign.center;
      case 'justify':
        return TextAlign.justify;
      case 'left':
        return TextAlign.left;
      default:
        return TextAlign.center;
    }
  }

  CanvasTextConfig copyWith({
    String? text,
    Color? fillColor,
    Color? textColor,
    Color? borderColor,
    double? borderWidth,
    TextAlign? textAlign,
    Color? outlineColor,
    double? outlineWidth,
    TextDecoration? textDecoration,
    NetworkFont? font,
    double? fontSize,
    double? borderRadius,
    double? contentPadding,
    double? shadowRadius,
    Color? textShadow,
    FontWeight? fontWeight,
    Color? borderShadow,
    double? textHeight,
    double? letterSpacing,
    double? shadowDistance,
    double? shadowAngle,
    bool? isDisableOutline,
    bool? isDisableShadow,
    bool? isDisableBackground,
    TextBoxWrapType? textBoxWrapType,
  }) {
    return CanvasTextConfig(
        text: text ?? this.text,
        borderShadow: borderShadow ?? this.borderShadow,
        font: font ?? this.font,
        textAlign: textAlign ?? this.textAlign,
        contentPadding: contentPadding ?? this.contentPadding,
        borderWidth: borderWidth ?? this.borderWidth,
        fillColor: fillColor ?? this.fillColor,
        outlineColor: outlineColor ?? this.outlineColor,
        outlineWidth: outlineWidth ?? this.outlineWidth,
        borderRadius: borderRadius ?? this.borderRadius,
        fontSize: fontSize ?? this.fontSize,
        fontWeight: fontWeight ?? this.fontWeight,
        borderColor: borderColor ?? this.borderColor,
        textColor: textColor ?? this.textColor,
        textDecoration: textDecoration ?? this.textDecoration,
        shadowRadius: shadowRadius ?? this.shadowRadius,
        textHeight: textHeight ?? this.textHeight,
        letterSpacing: letterSpacing ?? this.letterSpacing,
        shadowAngle: shadowAngle ?? this.shadowAngle,
        shadowDistance: shadowDistance ?? this.shadowDistance,
        textShadow: textShadow ?? this.textShadow,
        textBoxWrapType: textBoxWrapType ?? this.textBoxWrapType,
        isDisableOutline: isDisableOutline ?? this.isDisableOutline,
        isDisableShadow: isDisableShadow ?? this.isDisableShadow,
        isDisableBackground: isDisableBackground ?? this.isDisableBackground);
  }

  Map<String, dynamic> toMap() {
    String fontWeightValue = 'normal';
    switch (fontWeight) {
      case FontWeight.w700:
        fontWeightValue = 'bold';
        break;
      case FontWeight.w600:
        fontWeightValue = 'medium';
        break;
      case FontWeight.w500:
        fontWeightValue = 'normal';
        break;
      case FontWeight.w300:
        fontWeightValue = 'light';
        break;
    }

    return {
      'text': text,
      'borderShadow': borderShadow?.value,
      'font': {'fontFamily': font?.family, 'url': font?.url},
      'textAlign': textAlign.name,
      'contentPadding': contentPadding,
      'borderWidth': borderWidth,
      'fillColor': fillColor.value,
      'shadowRadius': shadowRadius,
      'fontSize': fontSize,
      'borderRadius': borderRadius,
      'borderColor': borderColor.value,
      'textColor': textColor.value,
      'textDecoration': textDecoration.toString().split('.')[0],
      'textShadow': textShadow.value,
      'outlineColor': outlineColor?.value,
      'outlineWidth': outlineWidth,
      'fontWeight': fontWeightValue,
      'textHeight': textHeight,
      'letterSpacing': letterSpacing,
      'shadowDistance': shadowDistance,
      'shadowAngle': shadowAngle,
      'textBoxWrapType': textBoxWrapType.name,
      'isDisableOutline': isDisableOutline,
      'isDisableShadow': isDisableShadow,
      'isDisableBackground': isDisableBackground
    };
  }
}

double? parseDouble(num? num){
  if(num != null){
    return num.toDouble();
  } else {
    return null;
  }
}
