/// FNose basic settings: the four top-level fields of
/// `/msupperlimbs-fnose/players/{id}/settings`.
class FnoseSettings {
  const FnoseSettings({
    this.presetId,
    required this.gameMode,
    required this.showInfoVideo,
    required this.totalTime,
    required this.targetSize,
    this.updatedAt,
  });

  final String? presetId;
  final String gameMode;
  final bool showInfoVideo;
  final int totalTime;
  final double targetSize;
  final DateTime? updatedAt;

  /// Parses the API envelope `{presetId, updatedAt, settings: {…}}`.
  factory FnoseSettings.fromApi(Map<String, dynamic> envelope) {
    final json = envelope['settings'] as Map<String, dynamic>;
    return FnoseSettings(
      presetId: envelope['presetId'] as String?,
      gameMode: json['gameMode'] as String? ?? 'leftHand',
      showInfoVideo: json['showInfoVideo'] as bool? ?? true,
      totalTime: json['totalTime'] as int? ?? 60,
      targetSize: (json['targetSize'] as num?)?.toDouble() ?? 1.0,
      updatedAt: _parseDate(envelope['updatedAt']),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
    'gameMode': gameMode,
    'showInfoVideo': showInfoVideo,
    'totalTime': totalTime,
    'targetSize': targetSize,
  };

  FnoseSettings copyWith({
    String? gameMode,
    bool? showInfoVideo,
    int? totalTime,
    double? targetSize,
  }) {
    return FnoseSettings(
      presetId: presetId,
      gameMode: gameMode ?? this.gameMode,
      showInfoVideo: showInfoVideo ?? this.showInfoVideo,
      totalTime: totalTime ?? this.totalTime,
      targetSize: targetSize ?? this.targetSize,
      updatedAt: DateTime.now().toUtc(),
    );
  }
}

/// FNose advanced settings (`settings.advanced` in the API).
///
/// [data] keeps the app's snake_case keys (`required_stable_time_ms`), which
/// the engine and the catalog use; the API speaks camelCase and the
/// conversion happens only in [fromApi] and [toApiJson].
class FnoseAdvSettings {
  const FnoseAdvSettings({this.presetId, required this.data, this.updatedAt});

  final String? presetId;
  final Map<String, dynamic> data;
  final DateTime? updatedAt;

  factory FnoseAdvSettings.fromApi(Map<String, dynamic> envelope) {
    final settings = envelope['settings'] as Map<String, dynamic>;
    final advanced = settings['advanced'] as Map<String, dynamic>? ?? {};
    return FnoseAdvSettings(
      presetId: envelope['presetId'] as String?,
      data: {for (final e in advanced.entries) camelToSnake(e.key): e.value},
      updatedAt: _parseDate(envelope['updatedAt']),
    );
  }

  /// `{advanced: {…}}` for `PATCH …/settings`.
  Map<String, dynamic> toApiJson() => {
    'advanced': {for (final e in data.entries) snakeToCamel(e.key): e.value},
  };

  double d(String key, double fallback) =>
      (data[key] as num?)?.toDouble() ?? fallback;

  int i(String key, int fallback) => (data[key] as num?)?.toInt() ?? fallback;

  FnoseAdvSettings copyWithData(Map<String, dynamic> data) {
    return FnoseAdvSettings(
      presetId: presetId,
      data: Map<String, dynamic>.from(data),
      updatedAt: DateTime.now().toUtc(),
    );
  }

  FnoseAdvSettings withValue(String key, num value) {
    final next = Map<String, dynamic>.from(data);
    next[key] = value;
    return copyWithData(next);
  }
}

String camelToSnake(String key) =>
    key.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]!.toLowerCase()}');

String snakeToCamel(String key) =>
    key.replaceAllMapped(RegExp('_([a-z0-9])'), (m) => m[1]!.toUpperCase());

DateTime? _parseDate(Object? value) =>
    value is String ? DateTime.parse(value) : null;
