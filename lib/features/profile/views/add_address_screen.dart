import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/address.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/primary_button.dart';
import '../viewmodels/profile_viewmodel.dart';

class AddAddressScreen extends ConsumerStatefulWidget {
  const AddAddressScreen({super.key, this.existingAddress});

  final Address? existingAddress;

  @override
  ConsumerState<AddAddressScreen> createState() => _AddAddressScreenState();
}

class _AddAddressScreenState extends ConsumerState<AddAddressScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _detailsController;
  late final TextEditingController _cityController;
  late final TextEditingController _stateController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _countryController;
  late final TextEditingController _phoneController;

  bool _isDefault = false;
  bool _isLoading = false;

  static const _tagOptions = ['Home', 'Office', 'Apartment', 'Parents'];

  @override
  void initState() {
    super.initState();
    final address = widget.existingAddress;
    _nameController = TextEditingController(text: address?.name ?? 'Home');
    _detailsController = TextEditingController(text: address?.details ?? '');
    _cityController = TextEditingController(text: address?.city ?? '');
    _stateController = TextEditingController(text: address?.state ?? '');
    _postalCodeController = TextEditingController(
      text: address?.postalCode ?? '',
    );
    _countryController = TextEditingController(
      text: address?.country ?? 'India',
    );
    _phoneController = TextEditingController(text: address?.phoneNumber ?? '');
    _isDefault = address?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _detailsController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final isEdit = widget.existingAddress != null;
      final newAddress = Address(
        id:
            widget.existingAddress?.id ??
            'addr_${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        details: _detailsController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: _countryController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        isDefault: _isDefault,
      );

      await ref.read(profileViewModelProvider.notifier).saveAddress(newAddress);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEdit
                  ? 'Address updated successfully!'
                  : 'Address added successfully!',
            ),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save address: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingAddress != null;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          isEdit ? 'Edit Address' : 'Add New Address',
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
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                children: [
                  // Address Label Quick Chips
                  Text(
                    'Address Type',
                    style: GoogleFonts.urbanist(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    children: _tagOptions.map((tag) {
                      final isSelected =
                          _nameController.text.trim().toLowerCase() ==
                          tag.toLowerCase();
                      return ChoiceChip(
                        label: Text(tag),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() => _nameController.text = tag);
                          }
                        },
                        selectedColor: Colors.white,
                        backgroundColor: AppColors.surface,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.black : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                        side: BorderSide(
                          color: isSelected ? Colors.white : AppColors.border,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Custom Name
                  AppTextField(
                    hint: 'Address Name (e.g. Home, Office)',
                    controller: _nameController,
                    prefixIcon: Icons.label_outline_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter an address name'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Street / Building Details
                  AppTextField(
                    hint: 'Street Address / Apartment / Flat',
                    controller: _detailsController,
                    prefixIcon: Icons.home_outlined,
                    maxLines: 2,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter street address'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // City & State
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          hint: 'City',
                          controller: _cityController,
                          prefixIcon: Icons.location_city_rounded,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'City is required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          hint: 'State',
                          controller: _stateController,
                          prefixIcon: Icons.map_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Postal Code & Country
                  Row(
                    children: [
                      Expanded(
                        child: AppTextField(
                          hint: 'Postal Code',
                          controller: _postalCodeController,
                          prefixIcon: Icons.pin_drop_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Postal code required'
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppTextField(
                          hint: 'Country',
                          controller: _countryController,
                          prefixIcon: Icons.public_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Phone Number
                  AppTextField(
                    hint: 'Phone Number (for delivery)',
                    controller: _phoneController,
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 20),

                  // Set as Default switch
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_outline_rounded,
                              color: Colors.white70,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Make this as default address',
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isDefault,
                          activeThumbColor: Colors.white,
                          activeTrackColor: const Color(0xFF4A5568),
                          inactiveThumbColor: Colors.grey,
                          inactiveTrackColor: AppColors.background,
                          onChanged: (val) => setState(() => _isDefault = val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Save Button
                  PrimaryButton(
                    text: isEdit ? 'Apply Changes' : 'Save Address',
                    isLoading: _isLoading,
                    onPressed: _handleSave,
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
