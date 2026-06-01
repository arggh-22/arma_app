// Smoke test for the root [ArmaApp] widget.
//
// The default Flutter "counter" template test was removed — this app has no
// counter. ArmaApp wires up real providers (auth bootstrap, default-server
// refresh) that perform network/platform work on first frame, so we only
// assert that the root widget constructs as a Widget without throwing. Full
// flows are covered by feature-level widget tests with provider overrides.

import 'package:arma_proxy_vpn_client/app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ArmaApp can be instantiated as a Widget', () {
    const app = ArmaApp();
    expect(app, isA<Widget>());
  });
}
