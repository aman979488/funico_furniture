import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreateNewPasswordScreen extends ConsumerWidget {
  const CreateNewPasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('CreateNewPasswordScreen')),
    );
  }
}
