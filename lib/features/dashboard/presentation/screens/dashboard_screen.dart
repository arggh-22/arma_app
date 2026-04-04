import 'package:flutter/material.dart';

/// Dashboard screen placeholder.
///
/// Will be replaced with full implementation in Plan 04.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Arma VPN')),
      body: const Center(child: Text('Dashboard')),
    );
  }
}
