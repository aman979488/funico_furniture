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
    this.isCompact = false,
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
  final bool isCompact;

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
        constraints: widget.isCompact
            ? const BoxConstraints(minWidth: 34, minHeight: 34)
            : null,
        padding: widget.isCompact ? EdgeInsets.zero : null,
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: AppColors.textHint,
          size: widget.isCompact ? 18 : 20,
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
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        isDense: widget.isCompact,
        contentPadding: widget.isCompact
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 14)
            : null,
        filled: widget.isCompact ? true : null,
        fillColor: widget.isCompact ? const Color(0xFF111B2A) : null,
        hintText: widget.hint,
        hintStyle: widget.isCompact
            ? const TextStyle(fontSize: 15, color: AppColors.textHint)
            : null,
        errorStyle: widget.isCompact ? const TextStyle(fontSize: 13) : null,
        prefixIcon: widget.prefixIcon == null
            ? null
            : Icon(
                widget.prefixIcon,
                color: AppColors.textHint,
                size: widget.isCompact ? 18 : 20,
              ),
        prefixIconConstraints: widget.isCompact
            ? const BoxConstraints(minWidth: 48, minHeight: 50)
            : null,
        suffixIcon: suffix,
        suffixIconConstraints: widget.isCompact
            ? const BoxConstraints(minWidth: 44, minHeight: 50)
            : null,
        border: widget.isCompact
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              )
            : null,
        enabledBorder: widget.isCompact
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: BorderSide.none,
              )
            : null,
        focusedBorder: widget.isCompact
            ? OutlineInputBorder(
                borderRadius: BorderRadius.circular(11),
                borderSide: const BorderSide(color: Colors.white, width: 1),
              )
            : null,
      ),
    );
  }
}
