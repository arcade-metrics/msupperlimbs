import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'mediapipe_types.dart';
import 'dart:io' show Platform;

/// Adapter que converte MLKit Pose para MediaPipePose (compatibilidade)
class MLKitPoseAdapter {
  PoseDetector? _poseDetector;
  MediaPipePose? _lastPose;
  bool _stridePaddingDetected = false;
  bool _stridePaddingLogged = false;
  
  // Pre-allocated NV21 buffer for performance
  Uint8List? _nv21Buffer;
  int _lastWidth = 0;
  int _lastHeight = 0;

  MediaPipePose? get lastPoseSmoothed => _lastPose;
  MediaPipePose? get lastPoseRaw => _lastPose;
  bool get hasStridePadding => _stridePaddingDetected;
  
  void _notifyStridePaddingDetected() {
    _stridePaddingDetected = true;
    if (!_stridePaddingLogged) {
      debugPrint('⚠️ Stride padding detected - this should be saved in device config');
      _stridePaddingLogged = true;
    }
  }

  Future<void> initialize() async {
    final options = PoseDetectorOptions(
      model: PoseDetectionModel.accurate,
      mode: PoseDetectionMode.stream,
    );
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> processGrayscaleBytes({
    required Uint8List yPlane,
    required int width,
    required int height,
    required int rotationDegrees,
    required bool mirrorHorizontal,
    required bool mirrorVertical,
    required bool isFrontCamera,
  }) async {
    if (_poseDetector == null) return;

    try {
      // Criar NV21 completo a partir do Y-plane (grayscale)
      // NV21 = Y plane + UV interleaved
      final expectedYSize = width * height;
      final uvSize = expectedYSize ~/ 2;
      
      // Pre-allocate buffer only when resolution changes (optimization)
      if (_nv21Buffer == null || _lastWidth != width || _lastHeight != height) {
        _nv21Buffer = Uint8List(expectedYSize + uvSize);
        // Pre-fill UV plane once (128 = neutral gray)
        _nv21Buffer!.fillRange(expectedYSize, _nv21Buffer!.length, 128);
        _lastWidth = width;
        _lastHeight = height;
      }
      
      // Auto-detectar stride: alguns dispositivos (Xiaomi) têm padding extra
      // Se Y-plane maior que esperado, usar apenas os bytes necessários
      if (yPlane.length > expectedYSize) {
        // Detectar stride (rowStride pode ser maior que width)
        final stride = yPlane.length ~/ height;
        
        if (!_stridePaddingDetected) {
          debugPrint('📐 Camera stride detected: $stride (width: $width, padding: ${stride - width})');
          _notifyStridePaddingDetected();
        }
        
        // Copiar Y-plane removendo padding diretamente para buffer reutilizável
        for (int row = 0; row < height; row++) {
          final srcOffset = row * stride;
          final dstOffset = row * width;
          _nv21Buffer!.setRange(dstOffset, dstOffset + width, yPlane, srcOffset);
        }
        
        await _processNV21Image(_nv21Buffer!, width, height, rotationDegrees);
        return;
      } else if (yPlane.length < expectedYSize) {
        _lastPose = null;
        return;
      }
      
      // Caminho rápido: copiar Y-plane direto para buffer pré-alocado
      _nv21Buffer!.setRange(0, expectedYSize, yPlane);
      
      await _processNV21Image(_nv21Buffer!, width, height, rotationDegrees);
    } catch (e) {
      debugPrint('MLKit error: $e');
      _lastPose = null;
    }
  }
  
  Future<void> _processNV21Image(
    Uint8List nv21Bytes,
    int width,
    int height,
    int rotationDegrees,
  ) async {
    try {
      final inputImage = _buildInputImage(
        nv21Bytes,
        width,
        height,
        rotationDegrees,
      );
      if (inputImage == null) {
        _lastPose = null;
        return;
      }

      final poses = await _poseDetector!.processImage(inputImage);
      
      if (poses.isEmpty) {
        _lastPose = null;
        return;
      }
      
      // Converter MLKit Pose para MediaPipePose
      _lastPose = _convertToMediaPipePose(poses.first, width, height);
    } catch (e) {
      debugPrint('❌ MLKit processing error: $e');
      _lastPose = null;
    }
  }

  InputImage? _buildInputImage(
    Uint8List nv21Bytes,
    int width,
    int height,
    int rotationDegrees,
  ) {
    final rotationIndex = (rotationDegrees ~/ 90).clamp(0, 3);
    final rotation = InputImageRotation.values[rotationIndex];

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(width.toDouble(), height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: width,
      ),
    );
  }

  MediaPipePose _convertToMediaPipePose(Pose pose, int width, int height) {
    final landmarks = <MediaPipePoseLandmark>[];

    // Apenas landmarks essenciais para o jogo
    final essentialTypes = {
      PoseLandmarkType.nose: 0,
      PoseLandmarkType.leftShoulder: 11,
      PoseLandmarkType.rightShoulder: 12,
      PoseLandmarkType.leftElbow: 13,
      PoseLandmarkType.rightElbow: 14,
      PoseLandmarkType.leftWrist: 15,
      PoseLandmarkType.rightWrist: 16,
      PoseLandmarkType.leftIndex: 19,
      PoseLandmarkType.rightIndex: 20,
    };

    essentialTypes.forEach((type, index) {
      final landmark = pose.landmarks[type];
      if (landmark != null) {
        landmarks.add(MediaPipePoseLandmark(
          index: index,
          x: landmark.x / width,
          y: landmark.y / height,
          z: landmark.z / width,
          visibility: landmark.likelihood,
        ));
      }
    });

    // A projeção das pontas dos dedos (leftIndexTip, rightIndexTip) 
    // é calculada em LandmarkSet.fromPose usando projectFingerTipLandmark

    return MediaPipePose(landmarks: landmarks);
  }

  Future<void> dispose() async {
    await _poseDetector?.close();
    _poseDetector = null;
  }
}

