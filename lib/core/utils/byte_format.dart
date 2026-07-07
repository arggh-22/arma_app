import 'dart:math' as math;

/// Formats a byte count using the largest sensible unit (B, KB, MB, GB, TB).
///
/// Shared by the home default-servers usage bar and the servers-tab
/// subscription group header so both render data usage identically.
String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  final exponent = math.min((math.log(bytes) / math.log(1024)).floor(), 4);
  final value = bytes / math.pow(1024, exponent);
  final fixed = value >= 10 || exponent == 0
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(1);
  return '$fixed ${units[exponent]}';
}
