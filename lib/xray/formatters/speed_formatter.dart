/// Formats a byte-per-second value into a human-readable speed string.
///
/// Examples:
/// - `formatSpeed(0)` → `'0 B/s'`
/// - `formatSpeed(1536)` → `'1.5 KB/s'`
/// - `formatSpeed(1048576)` → `'1.0 MB/s'`
String formatSpeed(int bytesPerSecond) {
  if (bytesPerSecond < 1024) {
    return '$bytesPerSecond B/s';
  } else if (bytesPerSecond < 1024 * 1024) {
    return '${(bytesPerSecond / 1024).toStringAsFixed(1)} KB/s';
  } else if (bytesPerSecond < 1024 * 1024 * 1024) {
    return '${(bytesPerSecond / (1024 * 1024)).toStringAsFixed(1)} MB/s';
  } else {
    return '${(bytesPerSecond / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB/s';
  }
}
