import 'dart:convert';
import 'dart:io';

/// Upload jobs kept on the device until they reach the server: one JSON
/// document per job, keyed by job id.
abstract class PendingUploadStore {
  Future<List<Map<String, dynamic>>> load();
  Future<void> save(String id, Map<String, dynamic> job);
  Future<void> delete(String id);
}

/// One file per job in [directory]. A match can carry megabytes of pose
/// frames, which is why this is not in shared preferences.
class FilePendingUploadStore implements PendingUploadStore {
  FilePendingUploadStore(this._directory);

  final Future<Directory> Function() _directory;

  Future<File> _file(String id) async {
    final dir = await _directory();
    await dir.create(recursive: true);
    return File('${dir.path}/$id.json');
  }

  @override
  Future<List<Map<String, dynamic>>> load() async {
    final dir = await _directory();
    if (!await dir.exists()) return [];
    final jobs = <Map<String, dynamic>>[];
    await for (final entry in dir.list()) {
      if (entry is! File || !entry.path.endsWith('.json')) continue;
      try {
        jobs.add(
          jsonDecode(await entry.readAsString()) as Map<String, dynamic>,
        );
      } catch (_) {
        // A half-written file from a crash: it can never be sent.
        await entry.delete();
      }
    }
    return jobs;
  }

  /// Written to a temporary file and renamed, so a crash never leaves a
  /// half-written job behind the real name.
  @override
  Future<void> save(String id, Map<String, dynamic> job) async {
    final file = await _file(id);
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(jsonEncode(job), flush: true);
    await tmp.rename(file.path);
  }

  @override
  Future<void> delete(String id) async {
    final file = await _file(id);
    if (await file.exists()) await file.delete();
  }
}

/// For tests.
class MemoryPendingUploadStore implements PendingUploadStore {
  final jobs = <String, Map<String, dynamic>>{};

  @override
  Future<List<Map<String, dynamic>>> load() async => [
    for (final job in jobs.values) jsonDecode(jsonEncode(job)),
  ].cast<Map<String, dynamic>>();

  @override
  Future<void> save(String id, Map<String, dynamic> job) async =>
      jobs[id] = jsonDecode(jsonEncode(job)) as Map<String, dynamic>;

  @override
  Future<void> delete(String id) async => jobs.remove(id);
}
