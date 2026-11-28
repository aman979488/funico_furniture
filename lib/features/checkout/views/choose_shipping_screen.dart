import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/utils/formatters.dart';
import '../viewmodels/checkout_viewmodel.dart';

class ChooseShippingScreen extends ConsumerStatefulWidget {
  const ChooseShippingScreen({super.key});

  @override
  ConsumerState<ChooseShippingScreen> createState() =>
      _ChooseShippingScreenState();
}

class _ChooseShippingScreenState extends ConsumerState<ChooseShippingScreen> {
  final List<ShippingOption> _options = const [
    ShippingOption(
      id: 'economy',
      title: 'Economy Delivery (No Fitting)',
      subtitle: 'Delivered in 5-7 business days, doorstep drop only',
      price: 600.0,
      estimatedDate: '5-7 Days',
    ),
    ShippingOption(
      id: 'standard',
      title: 'Standard Delivery & Fitting',
      subtitle: 'Delivery + professional carpenter fitting in 2-3 business days',
      price: 1200.0,
      estimatedDate: '2-3 Days',
    ),
    ShippingOption(
      id: 'express',
      title: 'Express Priority Installation',
      subtitle: 'Next day guaranteed delivery with instant installation',
      price: 2500.0,
      estimatedDate: '1-2 Days',
    ),
  ];

  late String _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId =
        ref.read(checkoutViewModelProvider).selectedShippingOption.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: Color(0xFF1F2937),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Choose Shipping & Fitting',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Select delivery speed & assembly preference',
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),

                  ..._options.map((opt) {
                    final isSelected = _selectedId == opt.id;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF5722)
                              : const Color(0xFFE5E7EB),
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          setState(() => _selectedId = opt.id);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFEEE4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.local_shipping_rounded,
                                  color: Color(0xFFFF5722),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            opt.title,
                                            style: GoogleFonts.urbanist(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: const Color(0xFF1F2937),
                                            ),
                                          ),
                                        ),
                                        Text(
                                          CurrencyFormatter.inRupees(opt.price),
                                          style: GoogleFonts.urbanist(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFFF5722),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      opt.subtitle,
                                      style: GoogleFonts.urbanist(
                                        fontSize: 12,
                                        color: const Color(0xFF6B7280),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Radio<String>(
                                value: opt.id,
                                groupValue: _selectedId,
                                activeColor: const Color(0xFFFF5722),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedId = val);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final chosen =
                        _options.firstWhere((o) => o.id == _selectedId);
                    ref
                        .read(checkoutViewModelProvider.notifier)
                        .selectShippingOption(chosen);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5722),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Apply Shipping',
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
