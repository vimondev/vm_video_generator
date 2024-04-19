import 'dart:math';

import 'package:myapp/vm_sdk/types/global.dart';

class MediaTransformConfig {
  final double scale;
  final double rotate;
  final int cropLeft;
  final int cropRight;
  final int cropTop;
  final int cropBottom;
  final int cropWidth;
  final int cropHeight;
  final String flipString;
  final String rotateString;

  MediaTransformConfig({
    this.scale = 1.0,
    this.rotate = 0.0,
    this.cropLeft = 0,
    this.cropRight = 0,
    this.cropTop = 0,
    this.cropBottom = 0,
    this.cropWidth = 0,
    this.cropHeight = 0,
    this.flipString = "",
    this.rotateString = "",
  });

  @override
  String toString() {
    return 'MediaTransformConfig(scale: $scale, rotate: $rotate, cropLeft: $cropLeft, cropRight: $cropRight, cropTop: $cropTop, cropBottom: $cropBottom, cropWidth: $cropWidth, cropHeight: $cropHeight, flipString: "$flipString", rotateString: "$rotateString")';
  }
}