import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';

part 'domain_rule_model.g.dart';

/// Hive-persisted model for custom domain routing rules.
///
/// Uses typeId 2 (typeId 0 = ServerConfigModel, typeId 1 = SubscriptionModel).
@HiveType(typeId: 2)
class DomainRuleModel extends HiveObject {
  @HiveField(0)
  final String domain;

  /// Action index: 0=proxy, 1=direct, 2=block.
  @HiveField(1)
  final int actionIndex;

  DomainRuleModel({required this.domain, required this.actionIndex});

  /// Maps this Hive model to the domain [DomainRule] entity.
  DomainRule toDomain() {
    const actions = ['proxy', 'direct', 'block'];
    return DomainRule(
      domain: domain,
      action: actions[actionIndex.clamp(0, 2)],
    );
  }

  /// Creates a [DomainRuleModel] from a domain [DomainRule] entity.
  factory DomainRuleModel.fromDomain(DomainRule rule) {
    final index = switch (rule.action) {
      'proxy' => 0,
      'direct' => 1,
      'block' => 2,
      _ => 0,
    };
    return DomainRuleModel(domain: rule.domain, actionIndex: index);
  }
}
