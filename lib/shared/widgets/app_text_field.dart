// TODO: app_text_field.dart
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.onChanged,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.maxLines = 1,
  });

  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final int maxLines;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscure = widget.isPassword;

  @override
  Widget build(BuildContext context) {
    Widget? suffix = widget.suffixIcon;
    if (widget.isPassword) {
      suffix = IconButton(
        onPressed: () => setState(() => _obscure = !_obscure),
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: 20,
        ),
      );
    }

    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      validator: widget.validator,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      maxLines: widget.isPassword ? 1 : widget.maxLines,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: widget.hint,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(widget.prefixIcon, color: AppColors.textHint, size: 20),
        suffixIcon: suffix,
      ),
    );
  }
}