import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:msupperlimbs/core/network/api_client.dart';

/// API limit for frames per pose chunk and events per batch.
const maxItemsPerUpload = 500;

/// `extra.upload_stats` of the match finish: what the app measured of its
/// own telemetry upload (monitoring query 6 in ciatec-core).
class UploadStats {
  int chunks = 0;
  int bytes = 0;
  int retries = 0;
  final _elapsed = Stopwatch();

  int get totalMs => _elapsed.elapsedMilliseconds;

  Map<String, dynamic> toJson() => {
    'chunks': chunks,
    'bytes': bytes,
    'total_ms': totalMs,
    'retries': retries,
  };
}

/// Sends idempotent uploads with retry on transient failures and keeps
/// [stats]. Only for requests that are safe to repeat (indexed chunks,
/// context, metrics, finish with an idempotency key).
class MatchUploader {
  MatchUploader({
    this.maxRetries = 2,
    this.retryDelay = const Duration(milliseconds: 500),
    Future<void> Function(Duration)? sleep,
  }) : _sleep = sleep ?? Future<void>.delayed;

  final int maxRetries;
  final Duration retryDelay;
  final Future<void> Function(Duration) _sleep;
  final stats = UploadStats();

  /// Counts [body] in [stats] (and as a chunk when [chunk]), then runs
  /// [call], retrying transient failures with a growing delay.
  Future<void> send(
    Map<String, dynamic> body,
    Future<void> Function() call, {
    bool chunk = false,
  }) async {
    stats.bytes += utf8.encode(jsonEncode(body)).length;
    if (chunk) stats.chunks += 1;
    stats._elapsed.start();
    try {
      for (var attempt = 0; ; attempt++) {
        try {
          await call();
          return;
        } catch (e) {
          if (attempt >= maxRetries || !isTransient(e)) rethrow;
          stats.retries += 1;
          await _sleep(retryDelay * (attempt + 1));
        }
      }
    } finally {
      stats._elapsed.stop();
    }
  }

  /// `{chunkIndex, frames}` per 500 frames; nothing when [frames] is empty.
  Future<void> sendPose(
    List<Map<String, dynamic>> frames,
    Future<void> Function(Map<String, dynamic> chunk) post,
  ) async {
    final chunks = chunked(frames, maxItemsPerUpload);
    for (var i = 0; i < chunks.length; i++) {
      final body = {'chunkIndex': i, 'frames': chunks[i]};
      await send(body, () => post(body), chunk: true);
    }
  }

  /// `{batchIndex, events}` per 500 events; nothing when [events] is empty.
  Future<void> sendEvents(
    List<Map<String, dynamic>> events,
    Future<void> Function(Map<String, dynamic> batch) post,
  ) async {
    final batches = chunked(events, maxItemsPerUpload);
    for (var i = 0; i < batches.length; i++) {
      final body = {'batchIndex': i, 'events': batches[i]};
      await send(body, () => post(body), chunk: true);
    }
  }
}

/// Network errors and 5xx; a 4xx is the request's fault and is not retried.
bool isTransient(Object error) {
  if (error is ApiException) return error.statusCode >= 500;
  return error is SocketException ||
      error is http.ClientException ||
      error is TimeoutException;
}

List<List<T>> chunked<T>(List<T> items, int size) => [
  for (var i = 0; i < items.length; i += size)
    items.sublist(i, min(i + size, items.length)),
];

/// Random UUID v4 for the finish `Idempotency-Key`.
String newIdempotencyKey([Random? random]) {
  final r = random ?? Random.secure();
  final bytes = List<int>.generate(16, (_) => r.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
  return [
    hex.sublist(0, 4).join(),
    hex.sublist(4, 6).join(),
    hex.sublist(6, 8).join(),
    hex.sublist(8, 10).join(),
    hex.sublist(10).join(),
  ].join('-');
}
