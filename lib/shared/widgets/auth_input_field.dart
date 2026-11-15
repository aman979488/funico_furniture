import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

/// Is field ke apne colors (theme ke inputDecorationTheme pe depend nahi)
class _FieldColors {
  _FieldColors._();

  static const Color fill = Color(0xFF1C2230); // navy tint
  static const Color fillFocused = Color(0xFF212A3B); // focus pe thoda halka
  static const Color idleBorder = Color(0xFF2B3345);
  static const Color hint = Color(0xFF8B93A7);
}

class AuthInputField extends StatefulWidget {
  const AuthInputField({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.readOnly = false,
    this.onTap,
    this.inputFormatters,
    this.prefixText,
    this.validator,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final bool readOnly;
  final VoidCallback? onTap;
  final List<TextInputFormatter>? inputFormatters;
  final String? prefixText;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<AuthInputField> createState() => _AuthInputFieldState();
}

class _AuthInputFieldState extends State<AuthInputField> {
  final FocusNode _focus = FocusNode();
  bool _obscure = true;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  OutlineInputBorder _border(Color color, double width) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    final iconColor = focused ? Colors.white : _FieldColors.hint;

    return TextFormField(
      controller: widget.controller,
      focusNode: _focus,
      obscureText: widget.isPassword && _obscure,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      textCapitalization: widget.textCapitalization,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      inputFormatters: widget.inputFormatters,
      validator: widget.validator,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      cursorColor: Colors.white,
      style: GoogleFonts.urbanist(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: focused ? _FieldColors.fillFocused : _FieldColors.fill,
        hintText: widget.hint,
        hintStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: _FieldColors.hint,
        ),
        prefixText: widget.prefixText,
        prefixStyle: GoogleFonts.urbanist(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        errorStyle: GoogleFonts.urbanist(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: AppColors.error,
        ),
        // left 0: icon ke baad ka gap prefixIcon ka padding sambhalta hai
        contentPadding: const EdgeInsets.fromLTRB(0, 19, 16, 19),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 18, right: 14),
          child: Icon(widget.icon, size: 22, color: iconColor),
        ),
        suffixIcon: widget.isPassword
            ? IconButton(
                splashRadius: 20,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  size: 22,
                  color: iconColor,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              )
            : null,
        border: _border(_FieldColors.idleBorder, 1),
        enabledBorder: _border(_FieldColors.idleBorder, 1),
        focusedBorder: _border(Colors.white, 1.5),
        errorBorder: _border(AppColors.error, 1),
        focusedErrorBorder: _border(AppColors.error, 1.5),
      ),
    );
  }
}
