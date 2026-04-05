import 'package:hive_ce/hive_ce.dart';
import 'package:arma_proxy_vpn_client/features/routing/data/models/domain_rule_model.dart';
import 'package:arma_proxy_vpn_client/features/routing/domain/entities/domain_rule.dart';

/// Provides CRUD operations for custom domain routing rules
/// stored in a Hive box.
class RoutingLocalDatasource {
  static const _boxName = 'domain_rules';
  final Box<DomainRuleModel> _box;

  RoutingLocalDatasource(this._box);

  /// Opens the Hive box for domain rules.
  static Future<Box<DomainRuleModel>> openBox() =>
      Hive.openBox<DomainRuleModel>(_boxName);

  /// Returns all stored domain rules as domain entities.
  List<DomainRule> getAllRules() =>
      _box.values.map((m) => m.toDomain()).toList();

  /// Adds a new domain rule.
  Future<void> addRule(DomainRule rule) =>
      _box.add(DomainRuleModel.fromDomain(rule));

  /// Updates the rule at [index] with new values.
  Future<void> updateRule(int index, DomainRule rule) =>
      _box.putAt(index, DomainRuleModel.fromDomain(rule));

  /// Deletes the rule at [index].
  Future<void> deleteRule(int index) => _box.deleteAt(index);

  /// Removes all domain rules.
  Future<void> clearAll() => _box.clear();
}
