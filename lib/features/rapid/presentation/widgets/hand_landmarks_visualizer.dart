import 'package:flutter/material.dart';

class HandLandmarksVisualizer extends StatelessWidget {
  final List<Map<String, dynamic>> landmarks;
  final double opacity;

  const HandLandmarksVisualizer({
    super.key,
    required this.landmarks,
    this.opacity = 0.6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.25,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(opacity),
        border: Border(
          left: BorderSide(
            color: Colors.white.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hand Landmarks',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white30),
          if (landmarks.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'No hand detected',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            )
          else
            Expanded(
              child: _buildLandmarksList(),
            ),
        ],
      ),
    );
  }

  Widget _buildLandmarksList() {
    return ListView.builder(
      itemCount: landmarks.length,
      itemBuilder: (context, index) {
        final landmark = landmarks[index];
        final x = landmark['x'] as double?;
        final y = landmark['y'] as double?;
        final z = landmark['z'] as double?;

        return Container(
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Point ${index + 1}',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'x: ${x?.toStringAsFixed(3) ?? "N/A"}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'y: ${y?.toStringAsFixed(3) ?? "N/A"}',
                style: const TextStyle(color: Colors.white),
              ),
              Text(
                'z: ${z?.toStringAsFixed(3) ?? "N/A"}',
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }
}

