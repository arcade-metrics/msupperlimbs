import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:msupperlimbs/features/fnose/data/repositories/fnose_match_repository.dart';
import 'package:msupperlimbs/features/fnose/domain/fnose_match_service.dart';

final fnoseMatchRepositoryProvider = Provider<FNoseMatchRepository>((ref) {
  return FNoseMatchRepository();
});

final fnoseMatchServiceProvider = Provider<FNoseMatchService>((ref) {
  return FNoseMatchService(ref.read(fnoseMatchRepositoryProvider));
});
