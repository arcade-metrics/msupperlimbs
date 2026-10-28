import 'package:flutter/services.dart';
import 'package:msupperlimbs/features/motion/domain/landmark_point.dart';

class MediaPipeFrameResult {
  const MediaPipeFrameResult({required this.pose, required this.hands});

  final List<LandmarkPoint> pose;
  final List<LandmarkPoint> hands;
}

class MediaPipeService {
  static const _channel = MethodChannel(
    'com.arcademetrics.msupperlimbs/mediapipe',
  );

  Future<void> initialize({String mode = 'both'}) async {
    await _channel.invokeMethod<bool>('initialize', {'mode': mode});
  }

  /// Single round-trip: one bitmap decode, pose + hands.
  Future<MediaPipeFrameResult> detectFrame({
    required Uint8List image,
    required int width,
    required int height,
    int rotation = 0,
    bool mirrorHorizontal = true,
    bool mirrorVertical = false,
    bool pose = true,
    bool hands = true,
  }) async {
    final raw = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('detectFrame', {
          'image': image,
          'width': width,
          'height': height,
          'rotation': rotation,
          'mirrorHorizontal': mirrorHorizontal,
          'mirrorVertical': mirrorVertical,
          'pose': pose,
          'hands': hands,
        });
    return MediaPipeFrameResult(
      pose: _parse(raw?['pose'] as List<dynamic>?, mirrored: mirrorHorizontal),
      hands: _parse(raw?['hands'] as List<dynamic>?),
    );
  }

  /// O frame da câmara frontal é espelhado antes da inferência, por isso o
  /// MediaPipe rotula os lados ao contrário (11↔12, 13↔14, 15↔16, 19↔20).
  /// Repomos a anatomia real do utente.
  static int anatomicalPoseIndex(int index, {required bool mirrored}) {
    if (!mirrored || index < 11 || index > 32) return index;
    return index.isOdd ? index + 1 : index - 1;
  }

  Future<void> dispose() async {
    await _channel.invokeMethod<bool>('dispose');
  }

  List<LandmarkPoint> _parse(List<dynamic>? raw, {bool mirrored = false}) {
    if (raw == null) return const [];
    return raw.whereType<Map>().map((e) {
      final point = LandmarkPoint.fromMap(Map<dynamic, dynamic>.from(e));
      final index = anatomicalPoseIndex(point.index, mirrored: mirrored);
      if (index == point.index) return point;
      return LandmarkPoint(
        index: index,
        x: point.x,
        y: point.y,
        z: point.z,
        visibility: point.visibility,
        presence: point.presence,
        handIndex: point.handIndex,
      );
    }).toList();
  }
}
