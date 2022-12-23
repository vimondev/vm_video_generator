import 'package:flutter/material.dart';
import 'package:myapp/vm_sdk/text_box/text/config.dart';
import 'package:network_font/network_font.dart';
import 'helper/text_box_wrap_type.dart';

class TextConfigBuilder {
  String? text;
  FontWeight? fontWeight;
  Color? fillColor;
  Color? textColor;
  Color? outlineColor;
  Color? borderColor;
  double? borderWidth;
  TextAlign? textAlign;
  TextDecoration? textDecoration;
  NetworkFont? font;
  double? fontSize;
  double? borderRadius;
  double? contentPadding;
  Color? textShadow;
  double? shadowRadius;
  double? textHeight;
  double? letterSpacing;
  Color? borderShadow;
  double? outlineWidth;
  double? shadowAngle;
  double? shadowDistance;
  bool? isDisableOutline;
  bool? isDisableShadow;
  bool? isDisableBackground;
  TextBoxWrapType? textBoxWrapType;

  TextConfigBuilder();

  TextConfigBuilder setText(String text) {
    this.text = text;
    return this;
  }

  TextConfigBuilder setFontWeight(FontWeight fontWeight) {
    this.fontWeight = fontWeight;
    return this;
  }

  TextConfigBuilder setFont(NetworkFont font) {
    this.font = font;
    return this;
  }

  TextConfigBuilder setFillColor(Color color) {
    fillColor = color;
    return this;
  }

  TextConfigBuilder setTextColor(Color color) {
    textColor = color;
    return this;
  }

  TextConfigBuilder setOutlineColor(Color color) {
    outlineColor = color;
    return this;
  }

  TextConfigBuilder setBorderColor(Color color) {
    borderColor = color;
    return this;
  }

  TextConfigBuilder setBorderWidth(double value) {
    borderWidth = value;
    return this;
  }

  TextConfigBuilder setTextAlign(TextAlign textAlign) {
    this.textAlign = textAlign;
    return this;
  }

  TextConfigBuilder setTextDecoration(TextDecoration value) {
    textDecoration = value;
    return this;
  }

  TextConfigBuilder setFontSize(double font) {
    fontSize = font;
    return this;
  }

  TextConfigBuilder setBorderRadius(double radius) {
    borderRadius = radius;
    return this;
  }

  TextConfigBuilder setContentPadding(double contentPadding) {
    this.contentPadding = contentPadding;
    return this;
  }

  TextConfigBuilder setTextShadow(Color color) {
    textShadow = color;
    return this;
  }

  TextConfigBuilder setShadowRadius(double radius) {
    shadowRadius = radius;
    return this;
  }

  TextConfigBuilder setTextHeight(double value) {
    textHeight = value;
    return this;
  }

  TextConfigBuilder setLetterSpacing(double value) {
    letterSpacing = value;
    return this;
  }

  TextConfigBuilder setBorderShadow(Color color) {
    borderShadow = color;
    return this;
  }

  TextConfigBuilder setOutlineWidth(double width) {
    outlineWidth = width;
    return this;
  }

  TextConfigBuilder setShadowAngle(double value) {
    shadowAngle = value;
    return this;
  }

  TextConfigBuilder setShadowDistance(double value) {
    shadowDistance = value;
    return this;
  }

  TextConfigBuilder setDisableOutline(bool isDisableOutline) {
    this.isDisableOutline = isDisableOutline;
    return this;
  }

  TextConfigBuilder setDisableShadow(bool isDisableShadow) {
    this.isDisableShadow = isDisableShadow;
    return this;
  }

  TextConfigBuilder setDisableBackground(bool isDisableBackground) {
    this.isDisableBackground = isDisableBackground;
    return this;
  }

  TextConfigBuilder setTextBoxWrapType(TextBoxWrapType textBoxWrapType) {
    this.textBoxWrapType = textBoxWrapType;
    return this;
  }

  CanvasTextConfig build() {
    return CanvasTextConfig(
        text: text ?? 'Input text',
        fontWeight: fontWeight ?? FontWeight.w700,
        fillColor: fillColor ?? Colors.black,
        textColor: textColor ?? Colors.white,
        outlineColor: outlineColor ?? Colors.transparent,
        borderColor: borderColor ?? Colors.transparent,
        borderWidth: borderWidth ?? 0.0,
        textAlign: textAlign ?? TextAlign.center,
        textDecoration: textDecoration ?? TextDecoration.none,
        font: font ?? NetworkFont('Roboto', url: ''),
        fontSize: fontSize ?? 14,
        borderRadius: borderRadius ?? 0,
        contentPadding: contentPadding ?? 0,
        textShadow: textShadow ?? Colors.transparent,
        shadowRadius: shadowRadius ?? 0,
        textHeight: textHeight ?? 1,
        letterSpacing: letterSpacing ?? 1,
        borderShadow: borderShadow,
        outlineWidth: outlineWidth ?? 0,
        shadowAngle: shadowAngle ?? 0,
        shadowDistance: shadowDistance ?? 0,
        isDisableOutline: isDisableOutline ?? false,
        isDisableShadow: isDisableShadow ?? false,
        isDisableBackground: isDisableBackground ?? false,
        textBoxWrapType: textBoxWrapType ?? TextBoxWrapType.wrapLine);
  }
}
