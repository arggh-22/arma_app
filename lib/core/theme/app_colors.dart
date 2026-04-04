import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';

/// Protocol badge colors for visual identification in server cards.
///
/// Each protocol gets a distinct, accessible color on both light and dark
/// backgrounds (white text overlay).
class AppColors {
  AppColors._();

  /// VLESS — Teal 600 (matches app accent).
  static const vless = Color(0xFF00897B);

  /// VMess — Blue 800.
  static const vmess = Color(0xFF1565C0);

  /// Trojan — Orange 900.
  static const trojan = Color(0xFFE65100);

  /// Shadowsocks — Purple 800.
  static const shadowsocks = Color(0xFF6A1B9A);

  /// Hysteria2 — Green 800.
  static const hysteria2 = Color(0xFF2E7D32);

  /// Returns the badge color for the given [type].
  static Color protocolColor(ProtocolType type) {
    return switch (type) {
      ProtocolType.vless => vless,
      ProtocolType.vmess => vmess,
      ProtocolType.trojan => trojan,
      ProtocolType.shadowsocks => shadowsocks,
      ProtocolType.hysteria2 => hysteria2,
    };
  }
}
