import 'package:arma_proxy_vpn_client/xray/formatters/speed_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSpeed', () {
    test('formats 0 bytes', () {
      expect(formatSpeed(0), '0 B/s');
    });

    test('formats bytes', () {
      expect(formatSpeed(512), '512 B/s');
    });

    test('formats kilobytes boundary', () {
      expect(formatSpeed(1024), '1.0 KB/s');
    });

    test('formats kilobytes with decimal', () {
      expect(formatSpeed(1536), '1.5 KB/s');
    });

    test('formats megabytes', () {
      expect(formatSpeed(1048576), '1.0 MB/s');
    });

    test('formats gigabytes', () {
      expect(formatSpeed(1073741824), '1.0 GB/s');
    });
  });
}
