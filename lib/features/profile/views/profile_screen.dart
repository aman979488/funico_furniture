import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/router/app_router.dart';
import '../../../core/services/pin_session.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/enums/user_role.dart';
import '../../../shared/widgets/app_brand_logo.dart';
import '../../auth/repositories/auth_repository.dart';
import '../viewmodels/profile_viewmodel.dart';

class _MenuItem {
  const _MenuItem(this.icon, this.label, {this.route});

  final IconData icon;
  final String label;
  final String? route;
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const _menu = [
    _MenuItem(
      Icons.person_outline_rounded,
      'Edit Profile',
      route: AppRoutes.editProfile,
    ),
    _MenuItem(Icons.location_on_outlined, 'Address', route: AppRoutes.address),
    _MenuItem(
      Icons.notifications_none_rounded,
      'Notification',
      route: AppRoutes.notificationSettings,
    ),
    _MenuItem(
      Icons.account_balance_wallet_outlined,
      'Payment',
      route: AppRoutes.paymentSettings,
    ),
    _MenuItem(Icons.shield_outlined, 'Security', route: AppRoutes.security),
    _MenuItem(Icons.language_rounded, 'Language', route: AppRoutes.language),
    _MenuItem(
      Icons.lock_outline_rounded,
      'Privacy Policy',
      route: AppRoutes.privacyPolicy,
    ),
    _MenuItem(
      Icons.help_outline_rounded,
      'Help Center',
      route: AppRoutes.helpCenter,
    ),
    _MenuItem(
      Icons.group_outlined,
      'Invite Friends',
      route: AppRoutes.inviteFriends,
    ),
  ];

  void _showAddVendorSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final shopNameController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add New Vendor',
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Vendor Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: shopNameController,
                    decoration: const InputDecoration(labelText: 'Shop / Store Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact / Phone'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email / Gmail'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                await ref.read(authRepositoryProvider).createVendor(
                                      name: nameController.text,
                                      shopName: shopNameController.text,
                                      contact: contactController.text,
                                      email: emailController.text,
                                      password: passwordController.text,
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Vendor Created Successfully!')),
                                  );
                                }
                              } catch (e) {
                                if (!sheetContext.mounted) return;
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create Vendor',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAddStaffSheet(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final contactController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    UserRole selectedRole = UserRole.admin;
    final formKey = GlobalKey<FormState>();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            left: 24,
            right: 24,
            top: 16,
          ),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Add New Staff Member',
                    style: GoogleFonts.urbanist(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Staff Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact / Phone'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email / Gmail'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => v == null || v.length < 6 ? 'Min 6 characters' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<UserRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Staff Role'),
                    items: const [
                      DropdownMenuItem(value: UserRole.admin, child: Text('Admin')),
                      DropdownMenuItem(value: UserRole.superAdmin, child: Text('Super Admin')),
                    ],
                    onChanged: (role) {
                      if (role != null) setState(() => selectedRole = role);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: isSaving
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setState(() => isSaving = true);
                              try {
                                await ref.read(authRepositoryProvider).createStaff(
                                      name: nameController.text,
                                      contact: contactController.text,
                                      email: emailController.text,
                                      password: passwordController.text,
                                      role: selectedRole,
                                    );
                                if (sheetContext.mounted) {
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Staff Member Created Successfully!')),
                                  );
                                }
                              } catch (e) {
                                setState(() => isSaving = false);
                                ScaffoldMessenger.of(sheetContext).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: const StadiumBorder(),
                      ),
                      child: isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              'Create Staff',
                              style: GoogleFonts.urbanist(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(UserRole role) {
    Color color = AppColors.primary;
    String label = 'Customer';
    if (role.isSuperAdmin) {
      color = Colors.purple;
      label = 'Super Admin';
    } else if (role.isAdmin) {
      color = Colors.redAccent;
      label = 'Admin';
    } else if (role.isVendor) {
      color = Colors.orange;
      label = 'Vendor';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Logout',
                style: GoogleFonts.urbanist(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 16),
              const Divider(color: AppColors.border),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to log out?',
                textAlign: TextAlign.center,
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _SheetButton(
                      label: 'Cancel',
                      background: AppColors.card,
                      foreground: AppColors.textPrimary,
                      onTap: () => Navigator.pop(sheetContext, false),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _SheetButton(
                      label: 'Yes, Logout',
                      background: AppColors.error,
                      foreground: Colors.white,
                      onTap: () => Navigator.pop(sheetContext, true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    try {
      if (Firebase.apps.isNotEmpty) await FirebaseAuth.instance.signOut();
      PinSession.lock();
      if (context.mounted) context.go(AppRoutes.letsYouIn);
    } on FirebaseAuthException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message ?? 'Could not log out. Please try again.',
          ),
        ),
      );
    }
  }

  Widget _buildAvatar(String? photoUrl) {
    ImageProvider? imageProvider;
    if (photoUrl != null && photoUrl.isNotEmpty) {
      if (!kIsWeb && File(photoUrl).existsSync()) {
        imageProvider = FileImage(File(photoUrl));
      } else if (photoUrl.startsWith('http://') ||
          photoUrl.startsWith('https://')) {
        imageProvider = NetworkImage(photoUrl);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 2),
      ),
      clipBehavior: Clip.antiAlias,
      child: imageProvider != null
          ? Image(
              image: imageProvider,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const Icon(
                Icons.person_rounded,
                size: 64,
                color: AppColors.textHint,
              ),
            )
          : const Icon(
              Icons.person_rounded,
              size: 64,
              color: AppColors.textHint,
            ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final user = Firebase.apps.isNotEmpty
        ? FirebaseAuth.instance.currentUser
        : null;

    final name = state.userProfile?.name.isNotEmpty == true
        ? state.userProfile!.name
        : (user?.displayName?.trim() ?? 'User');
    final email = state.userProfile?.email.isNotEmpty == true
        ? state.userProfile!.email
        : (user?.email ?? '');
    final photoUrl = state.userProfile?.photoUrl ?? user?.photoURL;
    final userRole = state.userProfile?.role ?? UserRole.customer;
    final selectedLanguage = state.selectedLanguage;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go(AppRoutes.home);
                          }
                        },
                        tooltip: 'Back',
                        icon: const Icon(
                          Icons.arrow_back_rounded,
                          color: AppColors.textPrimary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                          width: 32,
                          height: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const AppBrandLogo(size: 32),
                      const SizedBox(width: 10),
                      Text(
                        'Profile',
                        style: GoogleFonts.urbanist(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  SizedBox(
                    width: 120,
                    height: 120,
                    child: Stack(
                      children: [
                        Positioned.fill(child: _buildAvatar(photoUrl)),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () => context.push(AppRoutes.editProfile),
                              child: const SizedBox(
                                width: 34,
                                height: 34,
                                child: Icon(
                                  Icons.edit_rounded,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    name.isEmpty ? 'User' : name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.urbanist(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      email,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.urbanist(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  _buildRoleBadge(userRole),
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.border),
                  const SizedBox(height: 8),

                  // Standard Menu Items
                  for (final item in _menu)
                    _MenuTile(
                      icon: item.icon,
                      label: item.label,
                      trailing: item.label == 'Language'
                          ? selectedLanguage
                          : null,
                      onTap: () {
                        if (item.route != null) {
                          context.push(item.route!);
                        }
                      },
                    ),

                  // DYNAMIC VENDOR CONTROLS (Only for Vendor or Staff)
                  if (userRole.isVendor || userRole.isStaff) ...[
                    const Divider(color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Vendor Tools',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                    _MenuTile(
                      icon: Icons.add_box_outlined,
                      label: 'Add Product',
                      color: AppColors.primary,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Add Product Screen...')),
                        );
                      },
                    ),
                  ],

                  // DYNAMIC ADMIN CONTROLS (Only for Staff: Admin / SuperAdmin)
                  if (userRole.isStaff) ...[
                    const Divider(color: AppColors.border),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Admin Controls',
                          style: GoogleFonts.urbanist(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHint,
                          ),
                        ),
                      ),
                    ),
                    _MenuTile(
                      icon: Icons.storefront_outlined,
                      label: 'Add Vendor',
                      color: Colors.orange,
                      onTap: () => _showAddVendorSheet(context, ref),
                    ),
                    _MenuTile(
                      icon: Icons.badge_outlined,
                      label: 'Add Staff Member',
                      color: Colors.redAccent,
                      onTap: () => _showAddStaffSheet(context, ref),
                    ),
                    _MenuTile(
                      icon: Icons.sell_outlined,
                      label: 'Package Pricing Settings',
                      color: Colors.purple,
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening Package Pricing Settings...')),
                        );
                      },
                    ),
                  ],

                  const Divider(color: AppColors.border),
                  _MenuTile(
                    icon: Icons.logout_rounded,
                    label: 'Logout',
                    color: AppColors.error,
                    showChevron: false,
                    onTap: () => _confirmLogout(context),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
    this.color,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? trailing;
  final Color? color;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 24, color: tint),
            const SizedBox(width: 18),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.urbanist(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: tint,
                ),
              ),
            ),
            if (trailing != null) ...[
              Text(
                trailing!,
                style: GoogleFonts.urbanist(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (showChevron)
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.textHint,
              ),
          ],
        ),
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.label,
    required this.background,
    required this.foreground,
    required this.onTap,
  });

  final String label;
  final Color background;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 54,
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
