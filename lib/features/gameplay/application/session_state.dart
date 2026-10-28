import 'package:flutter_riverpod/flutter_riverpod.dart';

final sessionProvider = StateProvider<SessionState?>((ref) => null);

class SessionState {
  final String userId;
  final String sessionId;
  final String deviceModel;

  SessionState({
    required this.userId,
    required this.sessionId,
    required this.deviceModel,
  });
}
