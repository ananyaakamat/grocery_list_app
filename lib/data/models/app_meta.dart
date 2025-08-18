import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_meta.freezed.dart';
part 'app_meta.g.dart';

@freezed
class AppMeta with _$AppMeta {
  const factory AppMeta({
    required String key,
    required String value,
  }) = _AppMeta;

  factory AppMeta.fromJson(Map<String, dynamic> json) =>
      _$AppMetaFromJson(json);
}

extension AppMetaExtensions on AppMeta {
  // Convert to Map for SQLite insertion
  Map<String, dynamic> toMap() {
    return {
      'key': key,
      'value': value,
    };
  }

  // Create from SQLite Map
  static AppMeta fromMap(Map<String, dynamic> map) {
    return AppMeta(
      key: map['key'] as String,
      value: map['value'] as String,
    );
  }
}
