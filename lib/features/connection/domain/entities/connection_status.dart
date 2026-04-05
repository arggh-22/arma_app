/// Sealed class modeling VPN connection states.
///
/// Valid transitions:
///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
///   Connecting → Disconnected (on error)
sealed class ConnectionStatus {
  const ConnectionStatus();
}

/// VPN is not connected. Optionally carries the last error message.
class Disconnected extends ConnectionStatus {
  final String? lastError;
  const Disconnected([this.lastError]);
}

/// VPN is in the process of connecting to [serverName].
class Connecting extends ConnectionStatus {
  final String serverName;
  const Connecting(this.serverName);
}

/// VPN is connected to [serverName] since [connectedAt].
class Connected extends ConnectionStatus {
  final String serverName;
  final DateTime connectedAt;
  const Connected({required this.serverName, required this.connectedAt});
}

/// VPN is in the process of disconnecting.
class Disconnecting extends ConnectionStatus {
  const Disconnecting();
}
