// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subscription_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Provides the [SubscriptionRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.

@ProviderFor(subscriptionRepository)
final subscriptionRepositoryProvider = SubscriptionRepositoryProvider._();

/// Provides the [SubscriptionRepository] instance backed by Hive.
///
/// Keep-alive so the repository persists for the app's lifetime.

final class SubscriptionRepositoryProvider
    extends
        $FunctionalProvider<
          SubscriptionRepository,
          SubscriptionRepository,
          SubscriptionRepository
        >
    with $Provider<SubscriptionRepository> {
  /// Provides the [SubscriptionRepository] instance backed by Hive.
  ///
  /// Keep-alive so the repository persists for the app's lifetime.
  SubscriptionRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionRepositoryHash();

  @$internal
  @override
  $ProviderElement<SubscriptionRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  SubscriptionRepository create(Ref ref) {
    return subscriptionRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SubscriptionRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SubscriptionRepository>(value),
    );
  }
}

String _$subscriptionRepositoryHash() =>
    r'90386345e35c00f2f439e996153f80c432651b7e';

/// Riverpod notifier managing the subscription lifecycle.
///
/// Exposes methods to add, refresh, and delete subscriptions.
/// Handles:
/// - D-13: Replace ALL servers from a subscription on refresh
/// - D-14: Auto-select first new server if active was in refreshed subscription
/// - D-04 / CONF-07: Auto-refresh on launch for autoUpdate=true subscriptions

@ProviderFor(SubscriptionNotifier)
final subscriptionProvider = SubscriptionNotifierProvider._();

/// Riverpod notifier managing the subscription lifecycle.
///
/// Exposes methods to add, refresh, and delete subscriptions.
/// Handles:
/// - D-13: Replace ALL servers from a subscription on refresh
/// - D-14: Auto-select first new server if active was in refreshed subscription
/// - D-04 / CONF-07: Auto-refresh on launch for autoUpdate=true subscriptions
final class SubscriptionNotifierProvider
    extends $NotifierProvider<SubscriptionNotifier, List<Subscription>> {
  /// Riverpod notifier managing the subscription lifecycle.
  ///
  /// Exposes methods to add, refresh, and delete subscriptions.
  /// Handles:
  /// - D-13: Replace ALL servers from a subscription on refresh
  /// - D-14: Auto-select first new server if active was in refreshed subscription
  /// - D-04 / CONF-07: Auto-refresh on launch for autoUpdate=true subscriptions
  SubscriptionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'subscriptionProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$subscriptionNotifierHash();

  @$internal
  @override
  SubscriptionNotifier create() => SubscriptionNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Subscription> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Subscription>>(value),
    );
  }
}

String _$subscriptionNotifierHash() =>
    r'9b49aff4259eda03413fc633fca9c0633fda003b';

/// Riverpod notifier managing the subscription lifecycle.
///
/// Exposes methods to add, refresh, and delete subscriptions.
/// Handles:
/// - D-13: Replace ALL servers from a subscription on refresh
/// - D-14: Auto-select first new server if active was in refreshed subscription
/// - D-04 / CONF-07: Auto-refresh on launch for autoUpdate=true subscriptions

abstract class _$SubscriptionNotifier extends $Notifier<List<Subscription>> {
  List<Subscription> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<Subscription>, List<Subscription>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Subscription>, List<Subscription>>,
              List<Subscription>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
