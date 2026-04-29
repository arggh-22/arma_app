import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:arma_proxy_vpn_client/features/connection/data/datasources/vpn_platform_service.dart';

/// Riverpod provider for caching the Xray-core version string.
/// Fetched once from the native platform channel and cached.
final xrayVersionProvider = FutureProvider<String>((ref) async {
  final platformService = VpnPlatformService();
  final version = await platformService.getXrayVersion();
  return version;
});
