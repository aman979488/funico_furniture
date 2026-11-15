import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';

class AuthBrand extends StatelessWidget {
  const AuthBrand({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _bar(29),
        const SizedBox(height: 3),
        _bar(23),
        const SizedBox(height: 3),
        _bar(16),
      ],
    );
  }

  Widget _bar(double width) {
    return Container(
      width: width,
      height: 7,
      decoration: BoxDecoration(
        color: AppColors.textPrimary,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class AuthSocialDivider extends StatelessWidget {
  const AuthSocialDivider({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}

class AuthSocialIconRow extends StatelessWidget {
  const AuthSocialIconRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        _SocialIconButton(
          icon: FaIcon(FontAwesomeIcons.google, color: Color(0xFFEA4335)),
        ),
        SizedBox(width: 16),
        _SocialIconButton(
          icon: FaIcon(FontAwesomeIcons.apple, color: AppColors.textPrimary),
        ),
        SizedBox(width: 16),
        _SocialIconButton(
          icon: FaIcon(FontAwesomeIcons.facebookF, color: Color(0xFF1877F2)),
        ),
      ],
    );
  }
}

class _SocialIconButton extends StatelessWidget {
  const _SocialIconButton({required this.icon});

  final Widget icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(width: 44, height: 44, child: Center(child: icon)),
      ),
    );
  }
}

class AuthFooter extends StatelessWidget {
  const AuthFooter({
    super.key,
    required this.prompt,
    required this.action,
    required this.onTap,
  });

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            padding: const EdgeInsets.symmetric(horizontal: 5),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            action,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}
