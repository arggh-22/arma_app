import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/subscription.dart';

part 'subscription_model.g.dart';

/// Hive-persisted model for subscription data.
///
/// Uses explicit `@HiveField` indices with intentional gaps to allow
/// adding new fields in future schema versions without breaking existing data.
///
/// Index gaps: 4-5, 10-14
@HiveType(typeId: 1)
class SubscriptionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String url;

  @HiveField(3)
  final String userAgent;

  // GAP: 4-5 reserved for future fields

  @HiveField(6)
  final int? uploadBytes;

  @HiveField(7)
  final int? downloadBytes;

  @HiveField(8)
  final int? totalBytes;

  @HiveField(9)
  final int? expireMillis;

  // GAP: 10-14 reserved for future fields

  @HiveField(15)
  final int lastUpdatedMillis;

  @HiveField(16)
  final int addedAtMillis;

  @HiveField(17)
  final bool autoUpdate;

  SubscriptionModel({
    required this.id,
    required this.name,
    required this.url,
    this.userAgent = '',
    this.uploadBytes,
    this.downloadBytes,
    this.totalBytes,
    this.expireMillis,
    required this.lastUpdatedMillis,
    required this.addedAtMillis,
    this.autoUpdate = true,
  });

  /// Maps this Hive model to the domain [Subscription] entity.
  Subscription toDomain() => Subscription(
    id: id,
    name: name,
    url: url,
    userAgent: userAgent,
    uploadBytes: uploadBytes,
    downloadBytes: downloadBytes,
    totalBytes: totalBytes,
    expireDate:
        expireMillis != null
            ? DateTime.fromMillisecondsSinceEpoch(expireMillis!)
            : null,
    lastUpdated: DateTime.fromMillisecondsSinceEpoch(lastUpdatedMillis),
    addedAt: DateTime.fromMillisecondsSinceEpoch(addedAtMillis),
    autoUpdate: autoUpdate,
  );

  /// Creates a [SubscriptionModel] from a domain [Subscription] entity.
  factory SubscriptionModel.fromDomain(Subscription s) => SubscriptionModel(
    id: s.id,
    name: s.name,
    url: s.url,
    userAgent: s.userAgent,
    uploadBytes: s.uploadBytes,
    downloadBytes: s.downloadBytes,
    totalBytes: s.totalBytes,
    expireMillis: s.expireDate?.millisecondsSinceEpoch,
    lastUpdatedMillis: s.lastUpdated.millisecondsSinceEpoch,
    addedAtMillis: s.addedAt.millisecondsSinceEpoch,
    autoUpdate: s.autoUpdate,
  );
}
