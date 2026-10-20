import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FillProfileScreen extends ConsumerWidget {
  const FillProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('FillProfileScreen')),
    );
  }
}
