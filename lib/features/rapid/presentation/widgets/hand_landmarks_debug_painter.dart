import 'package:flutter/material.dart';

class HandLandmarksDebugPainter extends CustomPainter {
  final List<Map<String, dynamic>> landmarks;
  final Size imageSize;
  
  HandLandmarksDebugPainter({
    required this.landmarks,
    required this.imageSize,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    if (landmarks.isEmpty) return;
    
    // Define paints
    final dotPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;
      
    final linePaint = Paint()
      ..color = Colors.yellow
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    
    // Scale factors to map from normalized coordinates (0-1) to screen coordinates
    final double scaleX = size.width;
    final double scaleY = size.height;
    
    // Fingertip indices: 4 (thumb), 8 (index), 12 (middle), 16 (ring), 20 (pinky)
    // For each hand (21 landmarks per hand)
    final fingertipIndices = {4, 8, 12, 16, 20};
    
    // Draw dots only for fingertips
    for (int i = 0; i < landmarks.length; i++) {
      // Get landmark index within hand (0-20 for each hand)
      final landmarkIndexInHand = i % 21;
      
      // Check if this is a fingertip
      if (!fingertipIndices.contains(landmarkIndexInHand)) continue;
      
      final x = landmarks[i]['x'] as double? ?? 0;
      final y = landmarks[i]['y'] as double? ?? 0;
      
      // Corrigir espelhamento horizontal (1.0 - x inverte a coordenada x)
      final screenX = (1.0 - x) * scaleX;
      final screenY = y * scaleY;
      
      canvas.drawCircle(
        Offset(screenX, screenY),
        4,
        dotPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant HandLandmarksDebugPainter oldDelegate) {
    return oldDelegate.landmarks != landmarks;
  }
}
