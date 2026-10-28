class TouchDataParams {
  final String userId;
  final String sessionId;
  final String matchId;

  TouchDataParams({
    required this.userId,
    required this.sessionId,
    required this.matchId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TouchDataParams &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          sessionId == other.sessionId &&
          matchId == other.matchId;

  @override
  int get hashCode => userId.hashCode ^ sessionId.hashCode ^ matchId.hashCode;
}
