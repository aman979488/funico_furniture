import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FingerprintScreen extends ConsumerWidget {
  const FingerprintScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('FingerprintScreen')),
    );
  }
}
