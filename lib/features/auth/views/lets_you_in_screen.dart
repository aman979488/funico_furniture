import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LetsYouInScreen extends ConsumerWidget {
  const LetsYouInScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('LetsYouInScreen')),
    );
  }
}
