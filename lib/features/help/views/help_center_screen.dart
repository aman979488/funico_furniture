import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _selectedFaqCategory = 'General';

  static const _faqCategories = ['General', 'Order', 'Payment', 'Services'];

  static const _faqs = [
    {
      'category': 'General',
      'question': 'How do I track my furniture order?',
      'answer':
          'You can track your order status live under Orders > Track Order or by clicking on the notification updates sent to your phone and email.',
    },
    {
      'category': 'General',
      'question': 'Can I change my delivery address after placing an order?',
      'answer':
          'Yes, you can edit your shipping address within 2 hours of placing the order via the Orders page or by contacting Customer Service.',
    },
    {
      'category': 'Order',
      'question': 'What is Funica’s return and refund policy?',
      'answer':
          'We offer a 30-day hassle-free return window for all standard furniture items in original condition. Refunds are credited to your original payment method within 3-5 business days.',
    },
    {
      'category': 'Order',
      'question': 'How does doorstep assembly work?',
      'answer':
          'Our certified Funica technician arrives on the day of delivery to assemble and install your furniture completely free of cost.',
    },
    {
      'category': 'Payment',
      'question': 'What payment methods do you accept?',
      'answer':
          'We accept Credit/Debit cards (Visa, MasterCard, RuPay), Net Banking, UPI (Google Pay, PhonePe, Paytm), and Cash on Delivery.',
    },
    {
      'category': 'Payment',
      'question': 'Is my payment information secure?',
      'answer':
          'Yes, all payments are processed through PCI-DSS Level 1 certified gateways with end-to-end 256-bit encryption.',
    },
    {
      'category': 'Services',
      'question': 'Do you offer custom furniture design?',
      'answer':
          'Yes, reach out through Customer Service to connect with a Funica interior designer for personalized material and sizing customization.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final filteredFaqs = _faqs.where((f) {
      final matchesCategory = _selectedFaqCategory == 'General' ||
          f['category'] == _selectedFaqCategory;
      final matchesQuery = query.isEmpty ||
          f['question']!.toLowerCase().contains(query) ||
          f['answer']!.toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Help Center',
          style: GoogleFonts.urbanist(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
          tabs: const [
            Tab(text: 'FAQ'),
            Tab(text: 'Contact Us'),
          ],
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: TabBarView(
              controller: _tabController,
              children: [
                // FAQ Tab
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search FAQ...',
                        prefixIcon: const Icon(Icons.search_rounded),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _faqCategories.map((cat) {
                          final isSelected = _selectedFaqCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(cat),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedFaqCategory = cat);
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
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.border,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    for (final faq in filteredFaqs)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: Colors.transparent,
                          ),
                          child: ExpansionTile(
                            iconColor: Colors.white,
                            collapsedIconColor: Colors.white70,
                            title: Text(
                              faq['question']!,
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Text(
                                  faq['answer']!,
                                  style: const TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                // Contact Us Tab
                ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  children: [
                    _ContactOption(
                      icon: Icons.headset_mic_rounded,
                      title: 'Customer Service',
                      subtitle: '24/7 dedicated support representative',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Starting Live Support session...'),
                          ),
                        );
                      },
                    ),
                    _ContactOption(
                      icon: Icons.chat_rounded,
                      title: 'WhatsApp',
                      subtitle: '+91 98765 43210',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connecting to WhatsApp support...'),
                          ),
                        );
                      },
                    ),
                    _ContactOption(
                      icon: Icons.language_rounded,
                      title: 'Website',
                      subtitle: 'https://funica.furniture.com',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Opening funica.furniture.com...'),
                          ),
                        );
                      },
                    ),
                    _ContactOption(
                      icon: Icons.alternate_email_rounded,
                      title: 'Email',
                      subtitle: 'support@funica.com',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Email support: support@funica.com'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF283245),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: GoogleFonts.urbanist(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textHint),
      ),
    );
  }
}
