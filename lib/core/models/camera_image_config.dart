class CameraImageConfig {
  final String deviceModel;
  
  // INPUT: Applied to image BEFORE MediaPipe processing
  final int inputRotationDegrees; // 0, 90, 180, 270
  final bool inputMirrorHorizontal;
  final bool inputMirrorVertical;
  
  // OUTPUT: Applied to landmarks AFTER MediaPipe processing for display
  final int outputRotationDegrees; // 0, 90, 180, 270
  final bool outputMirrorHorizontal;
  final bool outputMirrorVertical;
  
  final bool hasStridePadding; // For devices like Xiaomi with rowStride > width

  const CameraImageConfig({
    required this.deviceModel,
    required this.inputRotationDegrees,
    required this.inputMirrorHorizontal,
    required this.inputMirrorVertical,
    required this.outputRotationDegrees,
    required this.outputMirrorHorizontal,
    required this.outputMirrorVertical,
    this.hasStridePadding = false, // Default: no padding
  });

  // Backward compatibility getters
  int get rotationDegrees => inputRotationDegrees;
  bool get mirrorHorizontal => inputMirrorHorizontal;
  bool get mirrorVertical => inputMirrorVertical;

  // Default para Android (must be fetched from Firebase)
  static const CameraImageConfig globalAndroid = CameraImageConfig(
    deviceModel: 'GLOBAL_ANDROID',
    inputRotationDegrees: 0,
    inputMirrorHorizontal: false,
    inputMirrorVertical: false,
    outputRotationDegrees: 0,
    outputMirrorHorizontal: false,
    outputMirrorVertical: false,
    hasStridePadding: false,
  );

  // Default para iOS (comportamento atual)
  static const CameraImageConfig globalIOS = CameraImageConfig(
    deviceModel: 'GLOBAL_IOS',
    inputRotationDegrees: 0,
    inputMirrorHorizontal: false,
    inputMirrorVertical: false,
    outputRotationDegrees: 0,
    outputMirrorHorizontal: false,
    outputMirrorVertical: false,
    hasStridePadding: false,
  );

  Map<String, dynamic> toJson() => {
        'device_model': deviceModel,
        // New separate input/output fields
        'input_rotation_degrees': inputRotationDegrees,
        'input_mirror_horizontal': inputMirrorHorizontal,
        'input_mirror_vertical': inputMirrorVertical,
        'output_rotation_degrees': outputRotationDegrees,
        'output_mirror_horizontal': outputMirrorHorizontal,
        'output_mirror_vertical': outputMirrorVertical,
        'has_stride_padding': hasStridePadding,
        // Backward compatibility
        'rotation_degrees': inputRotationDegrees,
        'mirror_horizontal': inputMirrorHorizontal,
        'mirror_vertical': inputMirrorVertical,
      };

  factory CameraImageConfig.fromJson(Map<String, dynamic> json) {
    // Support both new format and backward compatibility
    final inputRotation = json['input_rotation_degrees'] as int? ?? 
                         json['rotation_degrees'] as int? ?? 0;
    final inputMirrorH = json['input_mirror_horizontal'] as bool? ?? 
                        json['mirror_horizontal'] as bool? ?? false;
    final inputMirrorV = json['input_mirror_vertical'] as bool? ?? 
                        json['mirror_vertical'] as bool? ?? false;
    
    final outputRotation = json['output_rotation_degrees'] as int? ?? 
                          json['rotation_degrees'] as int? ?? 0;
    final outputMirrorH = json['output_mirror_horizontal'] as bool? ?? 
                         json['mirror_horizontal'] as bool? ?? false;
    final outputMirrorV = json['output_mirror_vertical'] as bool? ?? 
                         json['mirror_vertical'] as bool? ?? false;
    
    return CameraImageConfig(
      deviceModel: json['device_model'] as String? ?? 'GLOBAL_ANDROID',
      inputRotationDegrees: inputRotation,
      inputMirrorHorizontal: inputMirrorH,
      inputMirrorVertical: inputMirrorV,
      outputRotationDegrees: outputRotation,
      outputMirrorHorizontal: outputMirrorH,
      outputMirrorVertical: outputMirrorV,
      hasStridePadding: json['has_stride_padding'] as bool? ?? false,
    );
  }

  @override
  String toString() => 'CameraImageConfig('
      'model: $deviceModel, '
      'inputRot: $inputRotationDegrees°, '
      'inputMirror: [H:$inputMirrorHorizontal,V:$inputMirrorVertical], '
      'outputRot: $outputRotationDegrees°, '
      'outputMirror: [H:$outputMirrorHorizontal,V:$outputMirrorVertical], '
      'stride: ${hasStridePadding ? "padded" : "normal"})';
}


