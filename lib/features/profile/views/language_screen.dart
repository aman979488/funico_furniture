import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodels/profile_viewmodel.dart';

class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  static const _suggested = [
    'English (US)',
    'English (UK)',
  ];

  static const _languages = [
    'Hindi (हिन्दी)',
    'Spanish (Español)',
    'French (Français)',
    'German (Deutsch)',
    'Arabic (العربية)',
    'Russian (Русский)',
    'Japanese (日本語)',
    'Chinese (中文)',
    'Italian (Italiano)',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(profileViewModelProvider);
    final selected = state.selectedLanguage;
    final notifier = ref.read(profileViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Language',
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
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              children: [
                _HeaderLabel(label: 'Suggested'),
                for (final lang in _suggested)
                  _LanguageTile(
                    title: lang,
                    isSelected: selected.contains(lang.split(' ').first),
                    onTap: () => notifier.updateLanguage(lang),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                _HeaderLabel(label: 'Language'),
                for (final lang in _languages)
                  _LanguageTile(
                    title: lang,
                    isSelected: selected == lang,
                    onTap: () => notifier.updateLanguage(lang),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        label,
        style: GoogleFonts.urbanist(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.white : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: Colors.white,
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected ? Colors.white : AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
