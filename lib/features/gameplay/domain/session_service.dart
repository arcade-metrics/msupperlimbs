import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:msupperlimbs/core/domain/device_info_service.dart';

import '../application/session_state.dart';
import '../data/models/session_model.dart';
import '../data/models/session_log_model.dart';
import '../data/repositories/session_repository.dart';

class SessionService {
  final SessionRepository _sessionRepository;

  SessionService(this._sessionRepository);

  Future<void> createOrUpdateSession(WidgetRef ref, String userId) async {
    final now = DateTime.now().toUtc();
    final timeStampId = await generateTimeStampId(now);
    final date = DateFormat('yyyyMMdd').format(now); // YYYYMMDD
    final createdAt = now.toIso8601String(); // ISO 8601 timestamp
    final existingSession = await _sessionRepository.getSession(userId, date);
    final sessionId = existingSession?.sessionId ?? timeStampId;

    if (existingSession == null) {
      final newSession = SessionModel(
        sessionId: timeStampId,
        userId: userId,
        date: date,
        createdAt: createdAt,
      );
      await _sessionRepository.createSession(newSession);
    }

    final deviceInfo = await DeviceInfoService.getDeviceInfo();

    final newLog = SessionLogModel(
      logId: timeStampId,
      sessionId: sessionId,
      userId: userId,
      deviceModel: deviceInfo['deviceModel'] ?? 'Unknown',
      osVersion: deviceInfo['osVersion'] ?? 'Unknown',
      brand: deviceInfo['brand'] ?? 'Unknown',
      manufacturer: deviceInfo['manufacturer'] ?? 'Unknown',
      isPhysicalDevice: deviceInfo['isPhysicalDevice'] == true,
    );

    await _sessionRepository.addSessionLog(newLog);
    await initSessionState(ref, userId, sessionId);
  }

  Future<String> generateTimeStampId(DateTime now) async {
    final id =
        "${DateFormat('yyyyMMdd_HHmmss').format(now)}_${now.millisecondsSinceEpoch}";
    return id;
  }

  Future<void> initSessionState(
      WidgetRef ref, String userId, String sessionId) async {
    final deviceInfo = await DeviceInfoService.getDeviceInfo();
    ref.read(sessionProvider.notifier).state = SessionState(
      userId: userId,
      sessionId: sessionId,
      deviceModel: deviceInfo['deviceModel'] ?? 'Unknown',
    );
  }

  /// Retorna a resolução de câmera recomendada baseada no modelo do dispositivo
  /// Usa o deviceModel já coletado na sessão para evitar chamadas duplicadas
  static ResolutionPreset getRecommendedCameraResolution(String deviceModel) {
    // Dispositivos que precisam de resolução específica
    switch (deviceModel) {
      case 'FP3': // FairPhone 3
        return ResolutionPreset.high;
      // Adicione outros dispositivos problemáticos aqui
      // case 'iPhone SE':
      //   return ResolutionPreset.medium;
      // case 'Pixel 4a':
      //   return ResolutionPreset.low;
      default:
        return ResolutionPreset.medium; // Padrão para outros dispositivos
    }
  }
}
