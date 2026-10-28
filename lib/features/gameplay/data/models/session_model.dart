class SessionModel {
  final String sessionId;
  final String userId;
  final String date; // YYYYMMDD
  final String createdAt;

  SessionModel({
    required this.sessionId,
    required this.userId,
    required this.date,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'userId': userId,
      'date': date,
      'createdAt': createdAt,
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      sessionId: map['sessionId'],
      userId: map['userId'],
      date: map['date'],
      createdAt: map['createdAt']
    );
  }
}
