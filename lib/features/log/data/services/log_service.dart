import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Ring buffer log service for Xray-core debug events.
///
/// Keeps last [maxLines] lines in memory, streams new lines for live viewing
/// (MON-05), and exports all buffered lines to a file for sharing (MON-06).
///
/// Threat mitigations:
/// - T-03-10: Exported file shared only via user-initiated action, never sent
///   automatically.
/// - T-03-11: Ring buffer caps at [maxLines] lines, preventing unbounded memory
///   growth at debug verbosity.
class LogService {
  /// Maximum number of lines kept in the ring buffer.
  static const int maxLines = 5000;

  final _buffer = <String>[];
  final _controller = StreamController<String>.broadcast();

  /// Stream of new log lines for live viewing (MON-05).
  Stream<String> get logStream => _controller.stream;

  /// All currently buffered lines (unmodifiable snapshot).
  List<String> get lines => List.unmodifiable(_buffer);

  /// Number of buffered lines.
  int get lineCount => _buffer.length;

  /// Add a log line with timestamp prefix.
  ///
  /// Evicts the oldest line when buffer exceeds [maxLines].
  void addLine(String line) {
    final timestamp = DateTime.now().toIso8601String().substring(
      11,
      19,
    ); // HH:MM:SS
    final timestamped = '[$timestamp] $line';
    _buffer.add(timestamped);
    if (_buffer.length > maxLines) {
      _buffer.removeAt(0);
    }
    _controller.add(timestamped);
  }

  /// Export all buffered lines to a text file and share via system share sheet
  /// (MON-06).
  ///
  /// T-03-10: Only invoked by explicit user action (export button tap).
  Future<void> exportAndShare() async {
    if (_buffer.isEmpty) return;
    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/arma_vpn_log_$timestamp.txt');
    await file.writeAsString(_buffer.join('\n'));
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: 'Arma VPN Logs'),
    );
  }

  /// Clear all buffered lines.
  void clear() {
    _buffer.clear();
  }

  /// Dispose the stream controller.
  void dispose() {
    _controller.close();
  }
}
