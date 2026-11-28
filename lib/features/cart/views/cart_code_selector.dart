import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/cart_viewmodel.dart';

class CartCodeSelector extends ConsumerWidget {
  const CartCodeSelector({super.key});

  static const _createCodeAction = '__create_cart_code__';

  Future<void> _createCode(BuildContext context, WidgetRef ref) async {
    var codeName = '';
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Create a code'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Code name'),
          onChanged: (value) => codeName = value,
          onSubmitted: (value) => Navigator.of(dialogContext).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(codeName),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || !context.mounted) return;
    try {
      ref.read(cartViewModelProvider.notifier).createCode(name);
    } on ArgumentError catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message?.toString() ?? 'Invalid code.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartState = ref.watch(cartViewModelProvider);
    return PopupMenuButton<String>(
      tooltip: 'My Code',
      onSelected: (value) {
        if (value == _createCodeAction) {
          _createCode(context, ref);
        } else {
          ref.read(cartViewModelProvider.notifier).selectCode(value);
        }
      },
      itemBuilder: (context) => [
        for (final code in cartState.codes)
          PopupMenuItem<String>(
            value: code.id,
            child: Row(
              children: [
                if (code.id == cartState.selectedCodeId)
                  const Icon(Icons.check_rounded, size: 18)
                else
                  const SizedBox(width: 18),
                const SizedBox(width: 8),
                Text(code.name),
              ],
            ),
          ),
        const PopupMenuDivider(),
        const PopupMenuItem<String>(
          value: _createCodeAction,
          child: Row(
            children: [
              Icon(Icons.add_rounded, size: 18),
              SizedBox(width: 8),
              Text('Create new code'),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFFEEE4),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.folder_open_outlined,
              size: 16,
              color: Color(0xFFFF5722),
            ),
            const SizedBox(width: 6),
            const Text(
              'My Code',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF5722),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              cartState.selectedCode.name,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1F2937),
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}
