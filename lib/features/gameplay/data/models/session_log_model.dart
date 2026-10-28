class SessionLogModel {
  final String logId;
  final String sessionId;
  final String userId;
  final String deviceModel;
  final String osVersion;
  final String brand;
  final String manufacturer;
  final bool isPhysicalDevice;

  SessionLogModel({
    required this.logId,
    required this.sessionId,
    required this.userId,
    required this.deviceModel,
    required this.osVersion,
    required this.brand,
    required this.manufacturer,
    required this.isPhysicalDevice,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'sessionId': sessionId,
      'userId': userId,
      'deviceModel': deviceModel,
      'osVersion': osVersion,
      'brand': brand,
      'manufacturer': manufacturer,
      'isPhysicalDevice': isPhysicalDevice,
    };
  }

  factory SessionLogModel.fromMap(Map<String, dynamic> map) {
    return SessionLogModel(
      logId: map['logId'],
      sessionId: map['sessionId'],
      userId: map['userId'],
      deviceModel: map['deviceModel'] ?? "Unknown",
      osVersion: map['osVersion'] ?? "Unknown",
      brand: map['brand'] ?? "Unknown",
      manufacturer: map['manufacturer'] ?? "Unknown",
      isPhysicalDevice: map['isPhysicalDevice'] ?? false,
    );
  }
}
