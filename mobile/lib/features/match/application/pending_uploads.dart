import 'package:flutter/foundation.dart';
import 'package:msupperlimbs/features/match/data/pending_upload_store.dart';

/// What happened when a kept job was sent again.
sealed class JobOutcome {
  const JobOutcome();
}

/// Everything reached the server; the job is dropped.
class JobDone extends JobOutcome {
  const JobDone();
}

/// Still cannot be sent (offline, server down); [job] carries the progress.
class JobLater extends JobOutcome {
  const JobLater(this.job);
  final Map<String, dynamic> job;
}

/// The server refused it (a 4xx other than auth/rate limits): resending
/// would fail forever, so the job is dropped.
class JobRejected extends JobOutcome {
  const JobRejected(this.error);
  final Object error;
}

/// Sends one kept job of a given `kind` again.
typedef ReplayJob = Future<JobOutcome> Function(Map<String, dynamic> job);

/// Uploads kept on the device (matches, calibration runs) until they reach
/// ciatec-core. Every step they replay is idempotent on the server, so a
/// resend never duplicates data. Jobs belong to the user who played them
/// and are only sent while that user is logged in.
class PendingUploads {
  PendingUploads(this._store, {required this._handlers, required this._userId});

  final PendingUploadStore _store;
  final Map<String, ReplayJob> _handlers;
  final String? Function() _userId;
  Future<int>? _flushing;

  /// [job] needs `id`, `kind` and `userId`.
  Future<void> keep(Map<String, dynamic> job) =>
      _store.save(job['id'] as String, job);

  /// Sends the current user's jobs, oldest first, and returns how many
  /// reached the server. Stops at the first one that still cannot be sent:
  /// the others would fail the same way. One flush at a time.
  Future<int> flush() =>
      _flushing ??= _flush().whenComplete(() => _flushing = null);

  Future<int> _flush() async {
    final user = _userId();
    if (user == null) return 0;
    final jobs =
        (await _store.load()).where((job) => job['userId'] == user).toList()
          ..sort(
            (a, b) => (a['createdAt'] as String? ?? '').compareTo(
              b['createdAt'] as String? ?? '',
            ),
          );
    var sent = 0;
    for (final job in jobs) {
      final id = job['id'] as String;
      final replay = _handlers[job['kind']];
      if (replay == null) {
        await _store.delete(id);
        continue;
      }
      switch (await replay(job)) {
        case JobDone():
          await _store.delete(id);
          sent += 1;
        case JobRejected(:final error):
          debugPrint('Dropped pending upload $id: $error');
          await _store.delete(id);
        case JobLater(job: final progress):
          await _store.save(id, progress);
          return sent;
      }
    }
    return sent;
  }
}
