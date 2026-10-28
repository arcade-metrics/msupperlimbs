import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:msupperlimbs/core/models/camera_image_config.dart';
import 'package:msupperlimbs/core/services/camera_config_service.dart';
import 'mlkit_pose_adapter.dart';
import 'mediapipe_types.dart';

class CameraService {
  CameraController? controller;
  MLKitPoseAdapter? mpAdapter; // MLKit adapter (interface compatível)
  bool _isProcessing = false;
  CameraImageConfig? _imageConfig;

  /// Callback de pose (formato MediaPipe para compatibilidade)
  void Function(MediaPipePose pose, Size imageSize, int rotationDegrees,
      CameraLensDirection lensDirection)? onMpPoseDetected;

  /// Inicializa a câmera (target ~720x480). Medium geralmente aproxima 720x480.
  Future<void> initializeCamera(CameraDescription description) async {
    // Load device-specific camera configuration
    _imageConfig = await CameraConfigService.instance.getConfig();
    debugPrint('📸 Using camera config: $_imageConfig');

    controller = CameraController(
      description,
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller!.initialize();

    // Inicia o fluxo de frames
    controller!.startImageStream((CameraImage image) async {
      await processCameraImage(image);
    });
  }

  /// Interrompe o fluxo de imagens
  Future<void> stopImageStream() async {
    try {
      await controller?.stopImageStream();
    } catch (_) {}
  }

  /// Retorna o preview da câmera
  Widget getCameraPreview() {
    // Evita renderizar o preview antes do controller estar pronto
    if (controller?.value.isInitialized != true) {
      return const SizedBox.shrink();
    }
    return CameraPreview(controller!);
  }

  /// Processa o frame: envia Y-plane para MediaPipe adapter
  Future<void> processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Config já foi carregado na inicialização - não recarregar a cada frame
      if (mpAdapter != null && _imageConfig != null) {
        final Uint8List yPlane = image.planes[0].bytes;
        final int w = image.width;
        final int h = image.height;
        
        // Process frame with current config
        await mpAdapter!.processGrayscaleBytes(
          yPlane: yPlane,
          width: w,
          height: h,
          rotationDegrees: _imageConfig!.rotationDegrees,
          mirrorHorizontal: _imageConfig!.mirrorHorizontal,
          mirrorVertical: _imageConfig!.mirrorVertical,
          isFrontCamera:
              controller!.description.lensDirection == CameraLensDirection.front,
        );

        final mpPose = mpAdapter!.lastPoseSmoothed;
        if (onMpPoseDetected != null && mpPose != null) {
          onMpPoseDetected!(
            mpPose,
            Size(w.toDouble(), h.toDouble()),
            _imageConfig!.rotationDegrees,
            controller!.description.lensDirection,
          );
        }
      }
    } catch (e) {
      debugPrint('❌ CameraService error: $e');
    } finally {
      _isProcessing = false;
    }
  }

  /// Helper para fixar resolução alvo 720x480 (sem uso ainda, reservado)
  Size get targetResolution => const Size(720, 480);

  Future<void> dispose() async {
    await controller?.dispose();
  }
}
