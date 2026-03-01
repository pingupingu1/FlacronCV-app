// lib/features/home/presentation/widgets/pricing_section.dart
// 
// Drop this widget anywhere in your welcome_screen.dart
// Usage: PricingSection()

import 'package:flutter/material.dart';

class PricingSection extends StatefulWidget {
  const PricingSection({super.key});

  @override
  State<PricingSection> createState() => _PricingSectionState();
}

class _PricingSectionState extends State<PricingSection> {
  bool _isAnnual = false;
  int? _hoveredIndex;

  static const _plans = [
    {
      'name': 'Starter',
      'monthlyPrice': 39,
      'annualPrice': 33,
      'color': 0xFF43A047,
      'badge': null,
      'tagline': 'Perfect for solo operators',
      'features': [
        ['AI Assistant', '500 messages/mo'],
        ['Bookings', '100/month'],
        ['Employees', 'Up to 5'],
        ['Services', 'Up to 10'],
        ['Online Payments', 'Included'],
        ['Invoicing', 'Automatic'],
        ['Attendance Tracking', 'Basic'],
        ['Email Notifications', 'Included'],
        ['Push Notifications', 'Included'],
        ['SMS Notifications', null],
        ['Advanced Analytics', null],
        ['Custom Branding', null],
      ],
    },
    {
      'name': 'Growth',
      'monthlyPrice': 99,
      'annualPrice': 84,
      'color': 0xFFE65100,
      'badge': 'MOST POPULAR',
      'tagline': 'For growing businesses',
      'features': [
        ['AI Assistant', '2,000 messages/mo'],
        ['Bookings', '500/month'],
        ['Employees', 'Up to 15'],
        ['Services', 'Up to 30'],
        ['Online Payments', 'Included'],
        ['Invoicing', 'Automatic'],
        ['Attendance + Payroll', 'Included'],
        ['Email Notifications', 'Included'],
        ['Push Notifications', 'Included'],
        ['SMS Notifications', 'Included'],
        ['Advanced Analytics', 'Included'],
        ['Custom Branding', null],
      ],
    },
    {
      'name': 'Pro',
      'monthlyPrice': 249,
      'annualPrice': 211,
      'color': 0xFF6A1B9A,
      'badge': null,
      'tagline': 'For multi-location businesses',
      'features': [
        ['AI Assistant', '10,000 messages/mo'],
        ['Bookings', '2,000/month'],
        ['Employees', 'Up to 50'],
        ['Services', 'Up to 100'],
        ['Online Payments', 'Included'],
        ['Invoicing', 'Automatic'],
        ['GPS Attendance', 'Included'],
        ['All Notifications', 'Included'],
        ['Advanced Analytics', 'Full Reports'],
        ['SMS Notifications', 'Included'],
        ['Custom Branding', 'Included'],
        ['Up to 10 Locations', 'Included'],
      ],
    },
    {
      'name': 'Enterprise',
      'monthlyPrice': 499,
      'annualPrice': 424,
      'color': 0xFF1565C0,
      'badge': 'BEST VALUE',
      'tagline': 'Unlimited everything',
      'features': [
        ['AI Assistant', 'Unlimited'],
        ['Bookings', 'Unlimited'],
        ['Employees', 'Unlimited'],
        ['Services', 'Unlimited'],
        ['Online Payments', 'Included'],
        ['Invoicing', 'Automatic'],
        ['GPS Attendance', 'Included'],
        ['All Notifications', 'Unlimited'],
        ['Advanced Analytics', 'Custom Reports'],
        ['White Label', 'Included'],
        ['API Access', 'Included'],
        ['Dedicated Support', 'Included'],
      ],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 900;

    return Container(
      color: const Color(0xFFF8F9FA),
      padding: EdgeInsets.symmetric(
        vertical: 80,
        horizontal: isMobile ? 20 : 60,
      ),
      child: Column(
        children: [
          // ── Section header ───────────────────────────────────────────────
          _buildHeader(isMobile),
          const SizedBox(height: 48),
          // ── Toggle annual/monthly ────────────────────────────────────────
          _buildToggle(),
          const SizedBox(height: 48),
          // ── Plan cards ───────────────────────────────────────────────────
          isMobile
              ? _buildMobileCards()
              : _buildDesktopCards(),
          const SizedBox(height: 60),
          // ── Bottom CTA ───────────────────────────────────────────────────
          _buildBottomCta(),
          const SizedBox(height: 40),
          // ── Feature comparison table ─────────────────────────────────────
          _buildComparisonNote(),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isMobile) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE65100).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE65100).withOpacity(0.3)),
          ),
          child: const Text(
            'SIMPLE PRICING',
            style: TextStyle(
              color: Color(0xFFE65100),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'One Platform.\nEvery Tool You Need.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 32 : 44,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: const Color(0xFF1A1A1A),
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          'Replace Calendly + Gusto + Stripe + WhatsApp with one subscription.\nStart free for 14 days — no credit card required.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isMobile ? 15 : 17,
            color: Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleBtn('Monthly', !_isAnnual),
          _toggleBtn(
            'Annual',
            _isAnnual,
            badge: 'SAVE 15%',
          ),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, {String? badge}) {
    return GestureDetector(
      onTap: () => setState(() => _isAnnual = label == 'Annual'),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFE65100) : Colors.transparent,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.grey[600],
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: active ? Colors.white.withOpacity(0.25) : const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: active ? Colors.white : Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopCards() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(_plans.length, (i) {
        final plan = _plans[i];
        final isPopular = plan['badge'] == 'MOST POPULAR';
        return Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              i == 0 ? 0 : 8,
              isPopular ? 0 : 20,
              i == _plans.length - 1 ? 0 : 8,
              0,
            ),
            child: _PlanCard(
              plan: plan,
              isAnnual: _isAnnual,
              isHovered: _hoveredIndex == i,
              onHover: (v) => setState(() => _hoveredIndex = v ? i : null),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildMobileCards() {
    return Column(
      children: List.generate(_plans.length, (i) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _PlanCard(
          plan: _plans[i],
          isAnnual: _isAnnual,
          isHovered: false,
          onHover: (_) {},
        ),
      )),
    );
  }

  Widget _buildBottomCta() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE65100), Color(0xFFFF8F00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE65100).withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Not sure which plan?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Start your 14-day free trial on the Growth plan and explore everything.',
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 15),
                ),
              ],
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFFE65100),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'Start Free Trial',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonNote() {
    return Column(
      children: [
        const Text(
          'All plans include',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 24,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            '14-day free trial',
            'No credit card required',
            'Cancel anytime',
            'SSL secured',
            'GDPR compliant',
            '99.9% uptime SLA',
          ].map((t) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF43A047), size: 16),
              const SizedBox(width: 5),
              Text(t, style: const TextStyle(color: Color(0xFF444444), fontSize: 13)),
            ],
          )).toList(),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Individual Plan Card
// ─────────────────────────────────────────────────────────────────────────────
class _PlanCard extends StatelessWidget {
  final Map<String, dynamic> plan;
  final bool isAnnual;
  final bool isHovered;
  final ValueChanged<bool> onHover;

  const _PlanCard({
    required this.plan,
    required this.isAnnual,
    required this.isHovered,
    required this.onHover,
  });

  @override
  Widget build(BuildContext context) {
    final color = Color(plan['color'] as int);
    final isPopular = plan['badge'] == 'MOST POPULAR';
    final price = isAnnual ? plan['annualPrice'] as int : plan['monthlyPrice'] as int;
    final originalPrice = plan['monthlyPrice'] as int;
    final features = plan['features'] as List;

    return MouseRegion(
      onEnter: (_) => onHover(true),
      onExit: (_) => onHover(false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isPopular ? color : (isHovered ? color.withOpacity(0.4) : Colors.grey[200]!),
            width: isPopular ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular || isHovered
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.06),
              blurRadius: isPopular || isHovered ? 24 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Card header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isPopular ? color : color.withOpacity(0.05),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  if (plan['badge'] != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isPopular ? Colors.white.withOpacity(0.2) : color,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        plan['badge'] as String,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  // Plan name
                  Text(
                    plan['name'] as String,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isPopular ? Colors.white : color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    plan['tagline'] as String,
                    style: TextStyle(
                      fontSize: 13,
                      color: isPopular ? Colors.white.withOpacity(0.8) : Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$$price',
                        style: TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: isPopular ? Colors.white : const Color(0xFF1A1A1A),
                          height: 1,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6, left: 4),
                        child: Text(
                          '/mo',
                          style: TextStyle(
                            fontSize: 15,
                            color: isPopular ? Colors.white70 : Colors.grey[500],
                          ),
                        ),
                      ),
                      if (isAnnual) ...[
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isPopular ? Colors.white.withOpacity(0.2) : const Color(0xFF43A047).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'was \$$originalPrice',
                            style: TextStyle(
                              fontSize: 11,
                              color: isPopular ? Colors.white70 : const Color(0xFF43A047),
                              decoration: TextDecoration.lineThrough,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (isAnnual)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Billed \$${price * 12}/year',
                        style: TextStyle(
                          fontSize: 12,
                          color: isPopular ? Colors.white60 : Colors.grey[400],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Features list ────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  ...features.map<Widget>((f) {
                    final featureName = (f as List)[0] as String;
                    final featureValue = f[1] as String?;
                    final included = featureValue != null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: included ? color.withOpacity(0.1) : Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              included ? Icons.check : Icons.close,
                              size: 12,
                              color: included ? color : Colors.grey[400],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              featureName,
                              style: TextStyle(
                                fontSize: 13,
                                color: included ? const Color(0xFF333333) : Colors.grey[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          if (featureValue != null)
                            Text(
                              featureValue,
                              style: TextStyle(
                                fontSize: 12,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  // CTA button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/register'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isPopular ? color : Colors.white,
                        foregroundColor: isPopular ? Colors.white : color,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: isPopular ? 4 : 0,
                        shadowColor: color.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: isPopular ? BorderSide.none : BorderSide(color: color, width: 1.5),
                        ),
                      ),
                      child: Text(
                        'Start Free Trial',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
