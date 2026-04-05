import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:arma_proxy_vpn_client/features/server/domain/entities/server_config.dart';
import 'package:arma_proxy_vpn_client/features/server/presentation/providers/latency_provider.dart';

part 'best_server_provider.g.dart';

/// Auto-select the best server based on latency (D-16).
/// Reactive provider: re-evaluates whenever latency data changes.
@riverpod
ServerConfig? bestServer(Ref ref, List<ServerConfig> servers) {
  final latencyMap = ref.watch(latencyProvider);
  if (latencyMap.isEmpty) return null;

  // Filter to servers with successful latency data (> 0)
  final candidates = servers.where((s) {
    final latency = latencyMap[s.id];
    return latency != null && latency > 0;
  }).toList();

  if (candidates.isEmpty) return null;

  // Sort by latency ascending — lowest latency = best
  candidates.sort((a, b) {
    final la = latencyMap[a.id]!;
    final lb = latencyMap[b.id]!;
    return la.compareTo(lb);
  });

  return candidates.first;
}

/// Select the best server from a list, excluding a specific server.
/// Used for D-17 manual trigger and auto-fallback on connection failure.
/// Pure function — no Riverpod dependency, can be called from anywhere.
ServerConfig? selectBestServer(
  List<ServerConfig> servers,
  Map<String, int> latencyMap, {
  String? excludeServerId,
}) {
  final candidates = servers.where((s) {
    if (s.id == excludeServerId) return false;
    final latency = latencyMap[s.id];
    return latency != null && latency > 0;
  }).toList();

  if (candidates.isEmpty) return null;

  candidates.sort((a, b) {
    final la = latencyMap[a.id]!;
    final lb = latencyMap[b.id]!;
    return la.compareTo(lb);
  });

  return candidates.first;
}
