import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

typedef LinkLauncher = Future<bool> Function(Uri uri);

/// Opens external links (support / web cabinet) in the default browser.
/// Overridable in tests to assert launches without a real browser.
final linkLauncherProvider = Provider<LinkLauncher>(
  (ref) =>
      (uri) => launchUrl(uri, mode: LaunchMode.externalApplication),
);
