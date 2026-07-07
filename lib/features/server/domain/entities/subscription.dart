import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription.freezed.dart';
part 'subscription.g.dart';

/// Domain entity representing a subscription (a URL that provides server configs).
///
/// Tracks usage info from the `subscription-userinfo` HTTP response header
/// (upload/download/total bytes and expiry) and auto-update preferences.
@freezed
abstract class Subscription with _$Subscription {
  const factory Subscription({
    /// Unique identifier (UUID v4).
    required String id,

    /// User-facing display name.
    required String name,

    /// Subscription URL to fetch server configs from.
    required String url,

    /// Custom User-Agent header for this subscription (CONF-08).
    @Default('') String userAgent,

    /// Upload bytes consumed (from subscription-userinfo header).
    int? uploadBytes,

    /// Download bytes consumed (from subscription-userinfo header).
    int? downloadBytes,

    /// Total bandwidth quota in bytes (from subscription-userinfo header).
    int? totalBytes,

    /// Subscription expiration date (from subscription-userinfo header).
    DateTime? expireDate,

    /// When the subscription was last fetched/updated.
    required DateTime lastUpdated,

    /// When the subscription was added to the app.
    required DateTime addedAt,

    /// Whether to auto-refresh this subscription on app launch (CONF-07).
    @Default(true) bool autoUpdate,

    /// `support-url` header — opened from the "Support" action.
    String? supportUrl,

    /// `profile-web-page-url` header — opened from the "Renew"/"Cabinet" action.
    String? webPageUrl,

    /// `announce` header (decoded) — an admin notice shown with the subscription.
    String? announcement,
  }) = _Subscription;

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);
}
