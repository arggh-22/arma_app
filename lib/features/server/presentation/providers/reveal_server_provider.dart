import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the id of a server that should be scrolled into view.
///
/// Set when the user taps the active-server card on the dashboard. Whichever
/// surface owns that server reacts:
///   * default-api servers → the home [DefaultServersSection] expands the
///     server's block and scrolls it into view;
///   * imported servers → the Servers tab expands the server's group and
///     scrolls it into view.
///
/// The owning surface clears it back to null once handled, so the other
/// surface (which doesn't own the id) simply ignores it.
class RevealServerNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void request(String serverId) => state = serverId;

  void clear() => state = null;
}

final revealServerProvider =
    NotifierProvider<RevealServerNotifier, String?>(RevealServerNotifier.new);
