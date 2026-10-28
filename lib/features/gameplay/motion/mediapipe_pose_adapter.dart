import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart' as ml;

import 'mediapipe_pose_service.dart';
import 'mediapipe_types.dart';

/// Adapter to provide a MLKit-like interface backed by MediaPipe results
class MediaPipePoseAdapter {
  final MediaPipePoseService _native;
  
  // Dual-path: raw para logs/Firebase, smoothed para UI
  MediaPipePose? lastPoseRaw; // Pose original sem buffer (para análise biométrica)
  MediaPipePose? lastPoseSmoothed; // Pose suavizada com buffer (para UI)
  
  @Deprecated('Use lastPoseRaw ou lastPoseSmoothed')
  MediaPipePose? get lastPose => lastPoseRaw;

  // Buffer temporal para suavizar landmarks na UI
  final List<MediaPipePose?> _poseBuffer;

  MediaPipePoseAdapter(this._native, {int bufferSize = 3}) 
      : _poseBuffer = List.generate(bufferSize, (_) => null, growable: true);

  Future<void> initialize({
    String model = 'lite',
    String delegate = 'cpu',
    double detectionConfidence = 0.5,
    double trackingConfidence = 0.5,
    double presenceConfidence = 0.5,
  }) async {
    // Auto-detect GPU: tenta GPU primeiro, fallback para CPU se falhar
    String finalDelegate = delegate;
    if (delegate == 'gpu' || delegate == 'auto') {
      try {
        await _native.initialize(
          model: model,
          delegate: 'gpu',
          detectionConfidence: detectionConfidence,
          trackingConfidence: trackingConfidence,
          presenceConfidence: presenceConfidence,
        );
        debugPrint('✅ MediaPipe usando GPU delegate');
        return;
      } catch (e) {
        debugPrint('⚠️ GPU delegate falhou, usando CPU: $e');
        finalDelegate = 'cpu';
      }
    }
    
    // CPU fallback ou delegate explícito 'cpu'
    await _native.initialize(
      model: model,
      delegate: finalDelegate,
      detectionConfidence: detectionConfidence,
      trackingConfidence: trackingConfidence,
      presenceConfidence: presenceConfidence,
    );
    debugPrint('✅ MediaPipe usando CPU delegate');
  }

  /// Process a grayscale Y-plane buffer sized to the camera frame
  Future<void> processGrayscaleBytes({
    required Uint8List yPlane,
    required int width,
    required int height,
    int rotationDegrees = 0,
    bool mirrorHorizontal = false,
    bool mirrorVertical = false,
    bool isFrontCamera = true,
  }) async {
    try {
      final raw = await _native.processFrame(
        grayscaleBytes: yPlane,
        width: width,
        height: height,
        rotationDegrees: rotationDegrees,
        mirrorHorizontal: mirrorHorizontal,
        mirrorVertical: mirrorVertical,
        isFrontCamera: isFrontCamera,
      );
      final newPose = MediaPipePose.fromDynamicList(raw);

      // Path 1: raw para logs/Firebase (sem buffer, todos os frames)
      lastPoseRaw = newPose.landmarks.isEmpty ? null : newPose;

      // Path 2: smoothed para UI (com buffer, reduz piscar)
      _poseBuffer.removeAt(0);
      _poseBuffer.add(newPose.landmarks.isEmpty ? null : newPose);
      lastPoseSmoothed = _getSmoothedPose();
    } catch (e) {
      debugPrint('MediaPipePoseAdapter error: $e');
      lastPoseRaw = null;
      _poseBuffer.removeAt(0);
      _poseBuffer.add(null);
      lastPoseSmoothed = _getSmoothedPose();
    }
  }

  MediaPipePose? _getSmoothedPose() {
    final validPoses = _poseBuffer.whereType<MediaPipePose>().toList();
    if (validPoses.isEmpty) return null;

    // Retorna a mais recente válida (último elemento não-nulo)
    for (int i = _poseBuffer.length - 1; i >= 0; i--) {
      if (_poseBuffer[i] != null) return _poseBuffer[i];
    }

    // Fallback: média dos landmarks válidos (se houver > 1)
    if (validPoses.length > 1) {
      return _averagePoses(validPoses);
    }
    return validPoses.first;
  }

  MediaPipePose? _averagePoses(List<MediaPipePose> poses) {
    if (poses.isEmpty) return null;
    if (poses.length == 1) return poses.first;

    // Assume que todas têm o mesmo número de landmarks (ou zero)
    final landmarkCount = poses.first.landmarks.length;
    if (landmarkCount == 0) return null;

    final averaged = <MediaPipePoseLandmark>[];
    for (int i = 0; i < landmarkCount; i++) {
      double sumX = 0, sumY = 0, sumZ = 0, sumVis = 0;
      int count = 0;
      for (final pose in poses) {
        if (i < pose.landmarks.length) {
          final lm = pose.landmarks[i];
          sumX += lm.x;
          sumY += lm.y;
          sumZ += lm.z;
          sumVis += lm.visibility;
          count++;
        }
      }
      if (count > 0) {
        averaged.add(MediaPipePoseLandmark(
          index: i,
          x: sumX / count,
          y: sumY / count,
          z: sumZ / count,
          visibility: sumVis / count,
        ));
      }
    }
    return MediaPipePose(landmarks: averaged);
  }

  Future<void> dispose() async {
    await _native.dispose();
  }

  // Optional: temporary converter to MLKit Pose for compatibility (partial)
  ml.Pose? toMlkitPose() {
    // Not implemented here; FNose should use MediaPipePose directly in next phases
    return null;
  }
}


