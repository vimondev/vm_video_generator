import 'dart:ui';

import 'package:myapp/vm_sdk/text_box/text/base_text_info.dart';

import 'base_text_config.dart';

class VMTextConfig extends BaseTextConfig {
  final String path;
  final double ratio;
  final Size? size;
  final String? id;
  final String textId;
  final BaseTextInfo? textInfo;

  VMTextConfig(String text,
      {required this.path, required this.ratio, this.size, this.id, required this.textId, required this.textInfo})
      : super(text);

  factory VMTextConfig.fromMap(Map<String, dynamic> map, {BaseTextInfo? Function(Map<String, dynamic>?)? createInfo}) {
    return VMTextConfig(map['text'] ?? '',
        path: map['path'] ?? '',
        ratio: map['ratio'] ?? 0.0,
        textId: map['textId'] ?? '',
        textInfo: createInfo?.call(map['textInfo']));
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'path': path, 'textId': textId, 'id': id, 'ratio': ratio, 'textInfo': textInfo?.map};
  }
}
