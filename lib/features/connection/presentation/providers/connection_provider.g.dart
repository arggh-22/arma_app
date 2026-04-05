// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'connection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod notifier managing the VPN connection state machine.
///
/// State transitions:
///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
///   Connecting → Disconnected (on error or permission denied)
///
/// Uses [VpnPlatformService] for native MethodChannel/EventChannel communication
/// and [XrayConfigBuilder] to generate Xray JSON config from [ServerConfig] (D-02).
///
/// keepAlive: true — connection state persists across widget rebuilds.

@ProviderFor(ConnectionNotifier)
final connectionProvider = ConnectionNotifierProvider._();

/// Riverpod notifier managing the VPN connection state machine.
///
/// State transitions:
///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
///   Connecting → Disconnected (on error or permission denied)
///
/// Uses [VpnPlatformService] for native MethodChannel/EventChannel communication
/// and [XrayConfigBuilder] to generate Xray JSON config from [ServerConfig] (D-02).
///
/// keepAlive: true — connection state persists across widget rebuilds.
final class ConnectionNotifierProvider
    extends $NotifierProvider<ConnectionNotifier, ConnectionStatus> {
  /// Riverpod notifier managing the VPN connection state machine.
  ///
  /// State transitions:
  ///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
  ///   Connecting → Disconnected (on error or permission denied)
  ///
  /// Uses [VpnPlatformService] for native MethodChannel/EventChannel communication
  /// and [XrayConfigBuilder] to generate Xray JSON config from [ServerConfig] (D-02).
  ///
  /// keepAlive: true — connection state persists across widget rebuilds.
  ConnectionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectionNotifierHash();

  @$internal
  @override
  ConnectionNotifier create() => ConnectionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConnectionStatus value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConnectionStatus>(value),
    );
  }
}

String _$connectionNotifierHash() =>
    r'3a5ba8abce9742ac31f13b20716be3ef4be7beb9';

/// Riverpod notifier managing the VPN connection state machine.
///
/// State transitions:
///   Disconnected → Connecting → Connected → Disconnecting → Disconnected
///   Connecting → Disconnected (on error or permission denied)
///
/// Uses [VpnPlatformService] for native MethodChannel/EventChannel communication
/// and [XrayConfigBuilder] to generate Xray JSON config from [ServerConfig] (D-02).
///
/// keepAlive: true — connection state persists across widget rebuilds.

abstract class _$ConnectionNotifier extends $Notifier<ConnectionStatus> {
  ConnectionStatus build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ConnectionStatus, ConnectionStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ConnectionStatus, ConnectionStatus>,
              ConnectionStatus,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
