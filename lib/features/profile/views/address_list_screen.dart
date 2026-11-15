import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/address.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodels/profile_viewmodel.dart';

class AddressListScreen extends ConsumerWidget {
  const AddressListScreen({super.key});

  void _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    Address address,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Delete Address',
          style: GoogleFonts.urbanist(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${address.name}" address?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref
                  .read(profileViewModelProvider.notifier)
                  .deleteAddress(address.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Address "${address.name}" removed.')),
                );
              }
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final addresses = state.addresses;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Address',
          style: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: addresses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.location_off_outlined,
                              size: 40,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'No Addresses Found',
                            style: GoogleFonts.urbanist(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'You have not added any delivery address yet. Please add a new address to continue.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
                    itemCount: addresses.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final item = addresses[index];
                      return _AddressCard(
                        address: item,
                        onSetDefault: () {
                          ref
                              .read(profileViewModelProvider.notifier)
                              .setDefaultAddress(item.id);
                        },
                        onEdit: () {
                          context.push(AppRoutes.addAddress, extra: item);
                        },
                        onDelete: () =>
                            _showDeleteConfirmation(context, ref, item),
                      );
                    },
                  ),
          ),
        ),
      ),
      bottomSheet: SafeArea(
        child: Container(
          color: AppColors.background,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: PrimaryButton(
              text: 'Add New Address',
              icon: Icons.add_rounded,
              onPressed: () => context.push(AppRoutes.addAddress),
            ),
          ),
        ),
      ),
    );
  }
}

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.onSetDefault,
    required this.onEdit,
    required this.onDelete,
  });

  final Address address;
  final VoidCallback onSetDefault;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: address.isDefault ? Colors.white : AppColors.border,
          width: address.isDefault ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF28303F),
              shape: BoxShape.circle,
              border: Border.all(
                color: address.isDefault ? Colors.white70 : Colors.transparent,
              ),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      address.name,
                      style: GoogleFonts.urbanist(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (address.isDefault)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Default',
                          style: GoogleFonts.urbanist(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  address.fullAddress,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                if (address.phoneNumber != null &&
                    address.phoneNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    address.phoneNumber!,
                    style: const TextStyle(
                      color: AppColors.textHint,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                Row(
                  children: [
                    if (!address.isDefault)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: onSetDefault,
                        icon: const Icon(
                          Icons.check_circle_outline_rounded,
                          size: 16,
                          color: Colors.white70,
                        ),
                        label: const Text(
                          'Set Default',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 20,
                        color: Colors.white70,
                      ),
                      onPressed: onEdit,
                      tooltip: 'Edit Address',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 20,
                        color: AppColors.error,
                      ),
                      onPressed: onDelete,
                      tooltip: 'Delete Address',
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
