import 'package:flutter/material.dart';

import 'package:arma_proxy_vpn_client/core/constants/protocol_constants.dart';

/// Protocol accent colors for visual identification in server cards.
///
/// Tuned for the cyber-noir glass design: each protocol gets a bright
/// accent rendered as colored text inside a translucent capsule
/// (see [ProtocolBadge]), readable on both obsidian and light surfaces.
class AppColors {
  AppColors._();

  /// VLESS — Cyber Cyan (matches the secondary accent).
  static const vless = Color(0xFF22D3EE);

  /// VMess — Indigo 400.
  static const vmess = Color(0xFF818CF8);

  /// Trojan — Amber/Orange 400.
  static const trojan = Color(0xFFFB923C);

  /// Shadowsocks — Violet glow.
  static const shadowsocks = Color(0xFFC084FC);

  /// Hysteria2 — Signal green.
  static const hysteria2 = Color(0xFF4ADE80);

  /// Returns the accent color for the given [type].
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
