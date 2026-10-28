import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Service responsible for camera management in Rapid Game
class RapidCameraService {
  // Camera controller
  CameraController? _controller;
  
  // Processing state
  bool _isProcessing = false;
  
  // Callback for when a new frame is available
  Function(Uint8List imageBytes, Size imageSize)? onFrameAvailable;
  
  // Initialize the camera
  Future<void> initialize() async {
    // Get available cameras
    final cameras = await availableCameras();
    
    // Find front camera
    final frontCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    
    // Initialize controller with low resolution for better performance
    _controller = CameraController(
      frontCamera,
      ResolutionPreset.low, // Lower resolution for better performance
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );
    
    // Initialize the controller
    await _controller?.initialize();
    
    // Start image stream
    await startImageStream();
  }
  
  // Start processing camera frames
  Future<void> startImageStream() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return;
    }
    
    // Start the image stream
    _controller!.startImageStream(_processImage);
  }
  
  // Process incoming camera frames
  void _processImage(CameraImage image) {
    // Skip if already processing or no callback
    if (_isProcessing || onFrameAvailable == null) return;
    
    _isProcessing = true;
    
    try {
      // Convert YUV to bytes
      final bytes = _convertYUVtoBytes(image);
      
      // Get image size
      final size = Size(image.width.toDouble(), image.height.toDouble());
      
      // Call the callback
      onFrameAvailable!(bytes, size);
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }
  
  // Convert YUV format to bytes - simplified version using Y plane only (grayscale)
  Uint8List _convertYUVtoBytes(CameraImage image) {
    // Just use the Y plane (grayscale) for simplicity
    // This avoids complex YUV to RGB conversion issues
    final yPlane = image.planes[0].bytes;
    debugPrint('Using Y plane only: ${yPlane.length} bytes');
    return yPlane;
  }
  
  // Get camera preview widget
  Widget getCameraPreview() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return CameraPreview(_controller!);
  }
  
  // Stop the camera stream without disposing the controller
  Future<void> stopImageStream() async {
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
        debugPrint('Camera image stream stopped');
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
    
    // Reset processing state
    _isProcessing = false;
  }
  
  // Stop the camera and release all resources
  Future<void> dispose() async {
    debugPrint('Disposing camera resources');
    
    // Reset callback to prevent further processing
    onFrameAvailable = null;
    
    // Stop image stream first
    try {
      if (_controller != null && _controller!.value.isStreamingImages) {
        await _controller?.stopImageStream();
        debugPrint('Camera image stream stopped');
      }
    } catch (e) {
      debugPrint('Error stopping image stream: $e');
    }
    
    // Dispose controller
    try {
      await _controller?.dispose();
      debugPrint('Camera controller disposed');
    } catch (e) {
      debugPrint('Error disposing camera controller: $e');
    }
    
    // Clear references
    _controller = null;
    _isProcessing = false;
    
    debugPrint('Camera resources fully released');
  }
}
