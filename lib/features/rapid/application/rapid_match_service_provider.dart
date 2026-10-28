import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/rapid/data/repositories/rapid_match_repository.dart';
import 'package:msupperlimbs/features/rapid/domain/rapid_match_service.dart';

final rapidMatchRepositoryProvider = Provider<RapidMatchRepository>((ref) {
  return RapidMatchRepository();
});

final rapidMatchServiceProvider = Provider<RapidMatchService>((ref) {
  return RapidMatchService(ref.read(rapidMatchRepositoryProvider));
});
