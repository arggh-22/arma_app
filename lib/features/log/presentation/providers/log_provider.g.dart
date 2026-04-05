// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Singleton [LogService] instance that subscribes to VPN debug events.
///
/// Listens to the existing EventChannel `vpnEvents` stream, filtering for
/// `type == 'debug'` events (see Pitfall 7 in RESEARCH.md — debug events
/// already flow through the pipeline, we just need to capture them).

@ProviderFor(logService)
final logServiceProvider = LogServiceProvider._();

/// Singleton [LogService] instance that subscribes to VPN debug events.
///
/// Listens to the existing EventChannel `vpnEvents` stream, filtering for
/// `type == 'debug'` events (see Pitfall 7 in RESEARCH.md — debug events
/// already flow through the pipeline, we just need to capture them).

final class LogServiceProvider
    extends $FunctionalProvider<LogService, LogService, LogService>
    with $Provider<LogService> {
  /// Singleton [LogService] instance that subscribes to VPN debug events.
  ///
  /// Listens to the existing EventChannel `vpnEvents` stream, filtering for
  /// `type == 'debug'` events (see Pitfall 7 in RESEARCH.md — debug events
  /// already flow through the pipeline, we just need to capture them).
  LogServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logServiceHash();

  @$internal
  @override
  $ProviderElement<LogService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  LogService create(Ref ref) {
    return logService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LogService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LogService>(value),
    );
  }
}

String _$logServiceHash() => r'74c8586615293b13857392936b1a754ddfc8dc27';

/// Reactive log lines list for the log viewer.
///
/// Rebuilds state when new lines arrive via stream subscription, providing
/// a reactive snapshot of the current buffer contents.

@ProviderFor(LogLinesNotifier)
final logLinesProvider = LogLinesNotifierProvider._();

/// Reactive log lines list for the log viewer.
///
/// Rebuilds state when new lines arrive via stream subscription, providing
/// a reactive snapshot of the current buffer contents.
final class LogLinesNotifierProvider
    extends $NotifierProvider<LogLinesNotifier, List<String>> {
  /// Reactive log lines list for the log viewer.
  ///
  /// Rebuilds state when new lines arrive via stream subscription, providing
  /// a reactive snapshot of the current buffer contents.
  LogLinesNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'logLinesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$logLinesNotifierHash();

  @$internal
  @override
  LogLinesNotifier create() => LogLinesNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$logLinesNotifierHash() => r'3071dbcc633a6937174978196088d3882871940c';

/// Reactive log lines list for the log viewer.
///
/// Rebuilds state when new lines arrive via stream subscription, providing
/// a reactive snapshot of the current buffer contents.

abstract class _$LogLinesNotifier extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
