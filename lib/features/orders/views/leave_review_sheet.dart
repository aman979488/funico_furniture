import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LeaveReviewSheet extends ConsumerWidget {
  const LeaveReviewSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Scaffold(
      body: Center(child: Text('LeaveReviewSheet')),
    );
  }
}
