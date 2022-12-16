import 'dart:ui';

import 'base_text_config.dart';

class VMTextConfig extends BaseTextConfig {
  final String path;
  final double ratio;
  final Size? size;
  final String? id;
  final String textId;
  final Map<String, dynamic> textInfo;

  VMTextConfig(String text,
      {required this.path, required this.ratio, this.size, this.id, required this.textId, required this.textInfo})
      : super(text);

  factory VMTextConfig.fromMap(Map<String, dynamic> map) {
    return VMTextConfig(map['text'] ?? '',
        path: map['path'] ?? '',
        ratio: map['ratio'] ?? 0.0,
        textId: map['textId'] ?? '',
        textInfo: map['textInfo'] ?? {});
  }

  Map<String, dynamic> toMap() {
    return {'text': text, 'path': path, 'textId': textId, 'id': id, 'ratio': ratio, 'textInfo': textInfo};
  }
}
