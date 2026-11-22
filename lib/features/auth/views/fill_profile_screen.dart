import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/auth_input_field.dart';

class FillProfileScreen extends ConsumerStatefulWidget {
  final String? name;
  final String? email;

  const FillProfileScreen({super.key, this.name, this.email});

  @override
  ConsumerState<FillProfileScreen> createState() => _FillProfileScreenState();
}

class _FillProfileScreenState extends ConsumerState<FillProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderFieldKey = GlobalKey();

  final _picker = ImagePicker();
  OverlayEntry? _genderMenuEntry;
  Uint8List? _photoBytes;
  DateTime? _dob;
  String? _gender;
  bool _isSaving = false;
  bool _isLoadingProfile = true;

  static const _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController.text =
        widget.name ?? FirebaseAuth.instance.currentUser?.displayName ?? '';
    _emailController.text = widget.email ?? '';
    _loadSavedProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _dobController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _genderMenuEntry?.remove();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() => _photoBytes = bytes);
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.photo_library_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Gallery',
                  style: GoogleFonts.urbanist(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_outlined,
                  color: AppColors.textPrimary,
                ),
                title: Text(
                  'Camera',
                  style: GoogleFonts.urbanist(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pickPhoto(ImageSource.camera);
                },
              ),
              if (_photoBytes != null)
                ListTile(
                  leading: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                  ),
                  title: Text(
                    'Remove photo',
                    style: GoogleFonts.urbanist(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _photoBytes = null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 20),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.light().copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.primary,
            onPrimary: Colors.white,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      _dob = picked;
      _dobController.text =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';
    });
  }

  Future<void> _onContinue() async {
    if (_isSaving || _isLoadingProfile || !_formKey.currentState!.validate()) {
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in again to continue.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final phoneNumber = '+91${_phoneController.text.trim()}';
      final name = _nameController.text.trim();
      await user.updateDisplayName(name);
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'nickname': _nicknameController.text.trim(),
        'email': user.email,
        'dateOfBirth': _dobController.text.trim(),
        'phoneNumber': phoneNumber,
        'gender': _gender,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      context.go(AppRoutes.createPin, extra: true);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      debugPrint('Profile submission failed (${error.code}): ${error.message}');
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(_profileErrorMessage(error)),
            duration: const Duration(seconds: 8),
          ),
        );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _profileErrorMessage(FirebaseException error) {
    return switch (error.code) {
      'permission-denied' =>
        'Could not save your profile. Check Firestore security rules.',
      'unavailable' || 'network-request-failed' =>
        'Network error. Check your connection and try again.',
      _ =>
        error.message?.trim().isNotEmpty == true
            ? error.message!
            : 'Could not save your profile. Please try again.',
    };
  }

  Future<void> _loadSavedProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _isLoadingProfile = false;
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;

      final profile = snapshot.data();
      if (profile != null) {
        _nameController.text =
            profile['name'] as String? ?? _nameController.text;
        _nicknameController.text = profile['nickname'] as String? ?? '';
        _dobController.text = profile['dateOfBirth'] as String? ?? '';
        final phoneNumber = profile['phoneNumber'] as String? ?? '';
        _phoneController.text = phoneNumber.startsWith('+91')
            ? phoneNumber.substring(3)
            : phoneNumber;
        _gender = profile['gender'] as String?;
      }
    } on FirebaseException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load your saved profile.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  void _showGenderMenu(FormFieldState<String> field) {
    _genderMenuEntry?.remove();

    final fieldObject = _genderFieldKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context);
    final overlayObject = overlay.context.findRenderObject();
    if (fieldObject is! RenderBox || overlayObject is! RenderBox) return;

    final fieldTopLeft = fieldObject.localToGlobal(
      Offset.zero,
      ancestor: overlayObject,
    );
    const itemHeight = 48.0;
    const menuGap = 4.0;
    const edgePadding = 8.0;
    final menuWidth = fieldObject.size.width < 180
        ? fieldObject.size.width
        : 180.0;
    final menuLeft = fieldTopLeft.dx + fieldObject.size.width - menuWidth;
    final desiredHeight = _genders.length * itemHeight;
    final topPadding = MediaQuery.paddingOf(context).top + edgePadding;
    final menuTop = fieldTopLeft.dy - desiredHeight - menuGap;
    final constrainedTop = menuTop < topPadding ? topPadding : menuTop;
    final availableHeight = fieldTopLeft.dy - constrainedTop - menuGap;

    _genderMenuEntry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _closeGenderMenu,
              child: const SizedBox.expand(),
            ),
          ),
          Positioned(
            top: constrainedTop,
            left: menuLeft,
            width: menuWidth,
            child: Material(
              color: AppColors.surface,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppColors.border, width: 1.2),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: availableHeight),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: _genders
                        .map(
                          (gender) => SizedBox(
                            height: itemHeight,
                            child: InkWell(
                              onTap: () {
                                field.didChange(gender);
                                setState(() => _gender = gender);
                                _closeGenderMenu();
                              },
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    gender,
                                    style: GoogleFonts.urbanist(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    overlay.insert(_genderMenuEntry!);
  }

  void _closeGenderMenu() {
    _genderMenuEntry?.remove();
    _genderMenuEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Fill Your Profile',
          style: GoogleFonts.urbanist(
            color: AppColors.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go(AppRoutes.signup),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildAvatar(),
                    const SizedBox(height: 28),

                    AuthInputField(
                      controller: _nameController,
                      hint: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your full name';
                        if (value.length < 3) return 'Name is too short';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    AuthInputField(
                      controller: _nicknameController,
                      hint: 'Nickname (optional)',
                      icon: Icons.badge_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    AuthInputField(
                      controller: _dobController,
                      hint: 'Date of Birth',
                      icon: Icons.calendar_today_outlined,
                      readOnly: true,
                      onTap: _pickDob,
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Select your date of birth'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    AuthInputField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.email_outlined,
                      readOnly: true,
                    ),
                    const SizedBox(height: 16),

                    AuthInputField(
                      controller: _phoneController,
                      hint: 'Phone Number',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      prefixText: '+91  ',
                      textInputAction: TextInputAction.done,
                      validator: (v) {
                        final value = v?.trim() ?? '';
                        if (value.isEmpty) return 'Enter your phone number';
                        if (value.length != 10) {
                          return 'Enter a 10 digit number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    FormField<String>(
                      initialValue: _gender,
                      validator: (value) =>
                          value == null ? 'Select your gender' : null,
                      builder: (field) => InkWell(
                        key: _genderFieldKey,
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showGenderMenu(field),
                        child: InputDecorator(
                          decoration: _decoration(
                            'Gender',
                            Icons.wc_outlined,
                          ).copyWith(errorText: field.errorText),
                          isEmpty: field.value == null,
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  field.value ?? '',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.arrow_drop_down,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _isSaving || _isLoadingProfile
                            ? null
                            : _onContinue,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.disabled,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: _isSaving || _isLoadingProfile
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Continue',
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
      ),
    );
  }

  Widget _buildAvatar() {
    return GestureDetector(
      onTap: _showPhotoOptions,
      child: Stack(
        children: [
          CircleAvatar(
            radius: 54,
            backgroundColor: AppColors.card,
            backgroundImage: _photoBytes != null
                ? MemoryImage(_photoBytes!)
                : null,
            child: _photoBytes == null
                ? const Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: AppColors.textHint,
                  )
                : null,
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
              child: const Icon(Icons.edit, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _decoration(String hint, IconData icon) {
    OutlineInputBorder border(Color color, double width) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );

    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      hintText: hint,
      hintStyle: GoogleFonts.urbanist(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.textHint,
      ),
      errorStyle: GoogleFonts.urbanist(
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
        color: AppColors.error,
      ),
      contentPadding: const EdgeInsets.fromLTRB(0, 19, 16, 19),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      prefixIcon: Padding(
        padding: const EdgeInsets.only(left: 18, right: 14),
        child: Icon(icon, size: 22, color: AppColors.textHint),
      ),
      border: border(AppColors.border, 1.2),
      enabledBorder: border(AppColors.border, 1.2),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(AppColors.error, 1.2),
      focusedErrorBorder: border(AppColors.error, 1.6),
    );
  }
}
