import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String createdAt;
  final String? lastAccess;
  final bool hasConsent;
  final String? consentTimestamp;
  final String? consentUpdatedAt;
  final String? consentRevokedAt;
  final String? consentVersion;
  final String? ipAddress;

  UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.createdAt,
    this.lastAccess,
    this.hasConsent = false,
    this.consentTimestamp,
    this.consentUpdatedAt,
    this.consentRevokedAt,
    this.consentVersion,
    this.ipAddress,
  });

  // Convert a Model to a a Map (to save on Firebase)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'createdAt': createdAt,
      'lastAccess': lastAccess != null ? lastAccess! : null,
      'hasConsent': hasConsent,
      'consentTimestamp': consentTimestamp,
      'consentUpdatedAt': consentUpdatedAt,
      'consentRevokedAt': consentRevokedAt,
      'consentVersion': consentVersion,
      'ipAddress': ipAddress,
    };
  }

  // Create userModel from a Map (to get data from Firebase)
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'],
      displayName: map['displayName'],
      email: map['email'],
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'].toDate().toIso8601String()
          : map['createdAt'] ?? '',
      lastAccess: map['lastAccess'] is Timestamp
          ? map['lastAccess'].toDate().toIso8601String()
          : map['lastAccess'] ?? '',
      hasConsent: map['hasConsent'] ?? false,
      consentTimestamp: map['consentTimestamp'],
      consentUpdatedAt: map['consentUpdatedAt'],
      consentRevokedAt: map['consentRevokedAt'],
      consentVersion: map['consentVersion'],
      ipAddress: map['ipAddress'],
    );
  }

  UserModel copyWith({
    String? uid,
    String? displayName,
    String? email,
    String? createdAt,
    String? lastAccess,
    bool? hasConsent,
    String? consentTimestamp,
    String? consentUpdatedAt,
    String? consentRevokedAt,
    String? consentVersion,
    String? ipAddress,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      createdAt: createdAt ?? this.createdAt,
      lastAccess: lastAccess ?? this.lastAccess,
      hasConsent: hasConsent ?? this.hasConsent,
      consentTimestamp: consentTimestamp ?? this.consentTimestamp,
      consentUpdatedAt: consentUpdatedAt ?? this.consentUpdatedAt,
      consentRevokedAt: consentRevokedAt ?? this.consentRevokedAt,
      consentVersion: consentVersion ?? this.consentVersion,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }
}
