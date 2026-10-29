import 'dart:io';

/// What the app reports about itself in match context and finish metadata.
abstract final class AppInfo {
  /// Keep in step with `version` in pubspec.yaml.
  static const version = '0.1.0';

  static String get platform => Platform.operatingSystem;

  /// Trimmed to the API limit (64).
  static String get osVersion => _cut(Platform.operatingSystemVersion, 64);

  /// e.g. `pt_BR`, trimmed to the API limit (16).
  static String get locale => _cut(Platform.localeName, 16);

  static String _cut(String value, int max) =>
      value.length <= max ? value : value.substring(0, max);
}
