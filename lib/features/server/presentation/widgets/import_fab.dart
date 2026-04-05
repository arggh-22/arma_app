import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Expandable floating action button for server import options.
///
/// Placeholder — full implementation in Task 2.
class ImportFab extends ConsumerWidget {
  const ImportFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FloatingActionButton.extended(
      onPressed: () {},
      icon: const Icon(Icons.add),
      label: const Text('Import Server'),
    );
  }
}
