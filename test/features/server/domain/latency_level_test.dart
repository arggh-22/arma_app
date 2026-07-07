import 'package:arma_proxy_vpn_client/features/server/domain/latency_level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('latencyLevelFor (spec §3 bands)', () {
    test('classifies each band', () {
      expect(latencyLevelFor(null), LatencyLevel.untested);
      expect(latencyLevelFor(kLatencyTesting), LatencyLevel.testing);
      expect(latencyLevelFor(kLatencyFailed), LatencyLevel.timeout);
      expect(latencyLevelFor(0), LatencyLevel.excellent);
      expect(latencyLevelFor(120), LatencyLevel.excellent);
      expect(latencyLevelFor(121), LatencyLevel.medium);
      expect(latencyLevelFor(250), LatencyLevel.medium);
      expect(latencyLevelFor(251), LatencyLevel.poor);
      expect(latencyLevelFor(600), LatencyLevel.poor);
      expect(latencyLevelFor(601), LatencyLevel.timeout);
      expect(latencyLevelFor(5000), LatencyLevel.timeout);
    });
  });

  group('filter helpers', () {
    test('isLatencyWorking is true only within the reachable band', () {
      expect(isLatencyWorking(50), isTrue);
      expect(isLatencyWorking(600), isTrue);
      expect(isLatencyWorking(601), isFalse);
      expect(isLatencyWorking(kLatencyFailed), isFalse);
      expect(isLatencyWorking(null), isFalse);
      expect(isLatencyWorking(kLatencyTesting), isFalse);
    });

    test('isLatencyFailed is true for failure or timeout', () {
      expect(isLatencyFailed(kLatencyFailed), isTrue);
      expect(isLatencyFailed(601), isTrue);
      expect(isLatencyFailed(600), isFalse);
      expect(isLatencyFailed(50), isFalse);
      expect(isLatencyFailed(null), isFalse);
    });
  });
}
