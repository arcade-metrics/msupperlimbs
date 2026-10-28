import 'package:msupperlimbs/core/network/api_client.dart';

class FnosePregameRepository {
  FnosePregameRepository(this._api);

  final ApiClient _api;

  Future<FnosePregameSaveResponse> savePregame({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final json = await _api.postJson(
      '/fnose/pregame',
      accessToken: accessToken,
      body: payload,
    );
    return FnosePregameSaveResponse.fromJson(json);
  }
}

class FnosePregameSaveResponse {
  const FnosePregameSaveResponse({
    required this.id,
    required this.sessionId,
    required this.status,
    required this.poseChunkCount,
    required this.sensorChunkCount,
    required this.eventChunkCount,
  });

  final String id;
  final String sessionId;
  final String status;
  final int poseChunkCount;
  final int sensorChunkCount;
  final int eventChunkCount;

  factory FnosePregameSaveResponse.fromJson(Map<String, dynamic> json) {
    return FnosePregameSaveResponse(
      id: json['id'] as String,
      sessionId: json['session_id'] as String,
      status: json['status'] as String? ?? 'completed',
      poseChunkCount: json['pose_chunk_count'] as int? ?? 0,
      sensorChunkCount: json['sensor_chunk_count'] as int? ?? 0,
      eventChunkCount: json['event_chunk_count'] as int? ?? 0,
    );
  }
}
