import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:myapp/vm_sdk/impl/text_helper.dart';
import 'package:myapp/vm_sdk/types/types.dart';
import 'package:myapp/vm_sdk/impl/global_helper.dart';
import 'package:myapp/vm_sdk/widgets/customwebview.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';

class Rectangle {
  double _x, _y, _width, _height;

  Rectangle(this._x, this._y, this._width, this._height);

  double get x => _x;

  double get y => _y;

  double get width => _width;

  double get height => _height;
}

class VMText {
  final String _key;
  final String _value;
  final Rectangle _boundingBox;

  VMText(this._key, this._value, this._boundingBox);

  String get key => _key;

  String get value => _value;

  Rectangle get boundingBox => _boundingBox;
}

