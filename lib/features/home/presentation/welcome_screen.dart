// lib/features/home/presentation/welcome_screen.dart
import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(children: [

        // ── TOP BAR ────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(children: [
            Icon(Icons.business_center, color: Colors.orange[700], size: 28),
            const SizedBox(width: 8),
            const Text('FlacronControl',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 20)),
            const Spacer(),
            // ── GLOBE BUTTON ──────────────────────────────────────
            _GlobePicker(),
            const SizedBox(width: 6),
            OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.orange[700],
                side: BorderSide(color: Colors.orange[700]!),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text('Login'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700], foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), elevation: 0,
              ),
              child: const Text('Free Account'),
            ),
          ]),
        ),

        // ── BLACK NAV BAR — all 12 buttons, fills full width ──────
        Container(
          color: const Color(0xFF1A1A1A),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NB(icon: Icons.smart_toy_outlined,              label: 'AI Assistant',  route: '/ai-assistant', ctx: context),
              _NB(icon: Icons.calendar_today_outlined,         label: 'Bookings',      route: '/bookings',     ctx: context),
              _NB(icon: Icons.payment_outlined,                label: 'Payments',      route: '/payments',     ctx: context),
              _NB(icon: Icons.receipt_long_outlined,           label: 'Invoices',      route: '/invoices',     ctx: context),
              _NB(icon: Icons.people_outline,                  label: 'Employees',     route: '/employees',    ctx: context),
              _NB(icon: Icons.access_time_outlined,            label: 'Attendance',    route: '/attendance',   ctx: context),
              _NB(icon: Icons.account_balance_wallet_outlined, label: 'Payroll',       route: '/payroll',      ctx: context),
              _NB(icon: Icons.bar_chart_outlined,              label: 'Smart Booking', route: '/bookings',     ctx: context),
              _NB(icon: Icons.credit_card_outlined,            label: 'Stripe Pay',    route: '/payments',     ctx: context),
              _NB(icon: Icons.description_outlined,            label: 'Auto Invoice',  route: '/invoices',     ctx: context),
              _NB(icon: Icons.manage_accounts_outlined,        label: 'Emp Mgmt',      route: '/employees',    ctx: context),
              _NB(icon: Icons.notifications_outlined,          label: 'Reminders',     route: '/notifications',ctx: context),
            ],
          ),
        ),

        // ── SCROLLABLE BODY ─────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(children: [

              // HERO
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 70, horizontal: 40),
                decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.orange[700]!, Colors.orange[500]!],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                )),
                child: Column(children: [
                  const Icon(Icons.business_center, size: 70, color: Colors.white),
                  const SizedBox(height: 20),
                  const Text('Automate Your Business with AI',
                      style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  const Text('One powerful platform replacing Calendly, Gusto, Stripe, WhatsApp & more',
                      style: TextStyle(fontSize: 17, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0,
                    ),
                    child: const Text('Get Started Free',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),

              // PRICING
              const _PricingSection(),

              // ADD-ONS
              Container(
                width: double.infinity, color: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 52, horizontal: 40),
                child: Column(children: [
                  const Text('Power-Up Add-ons',
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  const SizedBox(height: 6),
                  Text('Optional extras for your subscription',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center),
                  const SizedBox(height: 28),
                  Wrap(spacing: 20, runSpacing: 20, alignment: WrapAlignment.center, children: [
                    _addon(Icons.sms_outlined,       'SMS Notifications', '\$10/mo', 'Automated SMS reminders',    Colors.blue),
                    _addon(Icons.smart_toy_outlined, 'Extra AI Messages', '\$20/mo', 'Unlimited AI conversations', Colors.purple),
                    _addon(Icons.palette_outlined,   'Custom Branding',   '\$50/mo', 'Your logo, colors & domain', Colors.orange),
                  ]),
                ]),
              ),

              // FINAL CTA
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 40),
                decoration: BoxDecoration(gradient: LinearGradient(
                  colors: [Colors.orange[700]!, Colors.orange[500]!],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                )),
                child: Column(children: [
                  const Text('Ready to Transform Your Business?',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 10),
                  const Text('Join thousands of businesses automating with FlacronControl',
                      style: TextStyle(fontSize: 16, color: Colors.white70), textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, foregroundColor: Colors.orange[700],
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)), elevation: 0,
                    ),
                    child: const Text('Start Your Free Trial',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ]),
              ),

              // FOOTER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 40),
                color: Colors.grey[900],
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.business_center, color: Colors.orange[400], size: 20),
                    const SizedBox(width: 8),
                    Text('FlacronControl',
                        style: TextStyle(color: Colors.orange[400], fontWeight: FontWeight.bold, fontSize: 16)),
                  ]),
                  const SizedBox(height: 6),
                  Text('© 2025 FlacronControl. All rights reserved.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ]),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Widget _addon(IconData icon, String title, String price, String desc, Color color) =>
    Container(
      width: 240, padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Container(padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, size: 26, color: color)),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(price, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(desc, style: TextStyle(color: Colors.grey[600], fontSize: 12), textAlign: TextAlign.center),
      ]),
    );
}

// ════════════════════════════════════════════════════════════════
// GLOBE LANGUAGE PICKER  — fully functional popup with 11 languages
// ════════════════════════════════════════════════════════════════
class _GlobePicker extends StatefulWidget {
  @override
  State<_GlobePicker> createState() => _GlobePickerState();
}

class _GlobePickerState extends State<_GlobePicker> {
  String _code = 'EN';

  static const _langs = [
    {'flag': '🇺🇸', 'name': 'English',    'code': 'EN'},
    {'flag': '🇸🇦', 'name': 'Arabic',     'code': 'AR'},
    {'flag': '🇫🇷', 'name': 'French',     'code': 'FR'},
    {'flag': '🇪🇸', 'name': 'Spanish',    'code': 'ES'},
    {'flag': '🇩🇪', 'name': 'German',     'code': 'DE'},
    {'flag': '🇮🇳', 'name': 'Hindi',      'code': 'HI'},
    {'flag': '🇮🇹', 'name': 'Italian',    'code': 'IT'},
    {'flag': '🇰🇷', 'name': 'Korean',     'code': 'KO'},
    {'flag': '🇧🇷', 'name': 'Portuguese', 'code': 'PT'},
    {'flag': '🇷🇺', 'name': 'Russian',    'code': 'RU'},
    {'flag': '🇨🇳', 'name': 'Chinese',    'code': 'ZH'},
  ];

  Future<void> _open(BuildContext ctx) async {
    final RenderBox box     = ctx.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(ctx).overlay!.context.findRenderObject() as RenderBox;
    final Offset topLeft    = box.localToGlobal(Offset.zero, ancestor: overlay);
    final Offset botRight   = box.localToGlobal(box.size.bottomRight(Offset.zero), ancestor: overlay);

    final result = await showMenu<String>(
      context: ctx,
      position: RelativeRect.fromLTRB(
        topLeft.dx,
        botRight.dy + 4,          // 4px gap below the button
        overlay.size.width - botRight.dx,
        0,
      ),
      elevation: 12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      items: _langs.map((l) {
        final selected = l['code'] == _code;
        return PopupMenuItem<String>(
          value: l['code'],
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: selected ? Colors.orange[50] : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Text(l['flag']!, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(child: Text(l['name']!, style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? Colors.orange[700] : Colors.black87,
              ))),
              Text(l['code']!, style: TextStyle(fontSize: 11, color: Colors.grey[400], fontWeight: FontWeight.w600)),
              if (selected) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle, size: 16, color: Colors.orange[700]),
              ],
            ]),
          ),
        );
      }).toList(),
    );

    if (result != null) setState(() => _code = result);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (ctx) => Tooltip(
        message: 'Change Language',
        child: InkWell(
          onTap: () => _open(ctx),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.language, color: Colors.grey, size: 18),
              const SizedBox(width: 4),
              Text(_code,
                  style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w700)),
              const SizedBox(width: 2),
              Icon(Icons.arrow_drop_down, color: Colors.grey[500], size: 16),
            ]),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// NAV BUTTON
// ════════════════════════════════════════════════════════════════
class _NB extends StatefulWidget {
  final IconData icon;
  final String label;
  final String route;
  final BuildContext ctx;
  const _NB({required this.icon, required this.label, required this.route, required this.ctx});
  @override State<_NB> createState() => _NBState();
}
class _NBState extends State<_NB> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit:  (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () => Navigator.pushNamed(widget.ctx, widget.route),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            margin: const EdgeInsets.symmetric(horizontal: 1),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: _hovered ? Colors.orange[700] : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(widget.icon, color: Colors.white, size: 14),
              const SizedBox(height: 3),
              Text(widget.label,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════
// PRICING SECTION
// ════════════════════════════════════════════════════════════════
class _PricingSection extends StatefulWidget {
  const _PricingSection();
  @override State<_PricingSection> createState() => _PricingSectionState();
}
class _PricingSectionState extends State<_PricingSection> {
  bool _annual = false;

  static const _plans = [
    {'name':'Starter','tagline':'For solo operators','monthly':39,'annual':33,'color':0xFF43A047,'popular':false,'features':[
      ['AI Assistant','500 msgs/mo',true],['Bookings','100/month',true],['Employees','Up to 5',true],
      ['Services','Up to 10',true],['Online Payments','Included',true],['Auto Invoicing','Included',true],
      ['Email Notifications','Included',true],['Push Notifications','Included',true],
      ['SMS Notifications','',false],['Advanced Analytics','',false]]},
    {'name':'Growth','tagline':'For growing businesses','monthly':99,'annual':84,'color':0xFFE65100,'popular':true,'features':[
      ['AI Assistant','2,000 msgs/mo',true],['Bookings','500/month',true],['Employees','Up to 15',true],
      ['Services','Up to 30',true],['Online Payments','Included',true],['Attendance + Payroll','Included',true],
      ['Email+Push+SMS','All channels',true],['Advanced Analytics','Included',true],
      ['3 Locations','Included',true],['Custom Branding','',false]]},
    {'name':'Pro','tagline':'Multi-location businesses','monthly':249,'annual':211,'color':0xFF6A1B9A,'popular':false,'features':[
      ['AI Assistant','10,000 msgs/mo',true],['Bookings','2,000/month',true],['Employees','Up to 50',true],
      ['Services','Up to 100',true],['GPS Attendance','Included',true],['All Notifications','Included',true],
      ['Custom Reports','Included',true],['Custom Branding','Included',true],
      ['10 Locations','Included',true],['White Label','',false]]},
    {'name':'Enterprise','tagline':'Unlimited everything','monthly':499,'annual':424,'color':0xFF1565C0,'popular':false,'features':[
      ['AI Assistant','Unlimited',true],['Bookings','Unlimited',true],['Employees','Unlimited',true],
      ['Services','Unlimited',true],['All Notifications','Unlimited',true],['Custom Reports','Full access',true],
      ['White Label','Included',true],['API Access','Included',true],
      ['Unlimited Locations','Included',true],['Dedicated Support','Included',true]]},
  ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width > 900;
    return Container(
      width: double.infinity, color: const Color(0xFFF4F6F8),
      padding: EdgeInsets.symmetric(vertical: 56, horizontal: wide ? 40 : 16),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange[200]!)),
          child: Text('PRICING PLANS', style: TextStyle(color: Colors.orange[700], fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2)),
        ),
        const SizedBox(height: 12),
        const Text('Simple, Transparent Pricing',
            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800), textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text('14-day free trial on all plans. No credit card required.',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        // Toggle
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32),
              border: Border.all(color: Colors.grey[300]!)),
          padding: const EdgeInsets.all(4),
          child: Row(mainAxisSize: MainAxisSize.min, children: [_tog('Monthly',!_annual), _tog('Annual  (Save 15%)',_annual)]),
        ),
        const SizedBox(height: 32),
        // Cards
        wide
          ? Row(crossAxisAlignment: CrossAxisAlignment.start,
              children: _plans.asMap().entries.map((e) => Expanded(child: Padding(
                padding: EdgeInsets.only(left: e.key==0?0:8, right: e.key==3?0:8),
                child: _Card(plan: e.value, annual: _annual)))).toList())
          : Column(children: _plans.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _Card(plan: p, annual: _annual))).toList()),
        const SizedBox(height: 28),
        Wrap(spacing: 20, runSpacing: 8, alignment: WrapAlignment.center,
          children: ['✅  14-day free trial','✅  No credit card','✅  Cancel anytime','✅  SSL secured','✅  99.9% uptime']
              .map((t) => Text(t, style: TextStyle(color: Colors.grey[600], fontSize: 13))).toList()),
      ]),
    );
  }

  Widget _tog(String label, bool active) => GestureDetector(
    onTap: () => setState(() => _annual = label.startsWith('Annual')),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
      decoration: BoxDecoration(
        color: active ? Colors.orange[700] : Colors.transparent,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(label, style: TextStyle(
        color: active ? Colors.white : Colors.grey[600],
        fontWeight: FontWeight.w600, fontSize: 13)),
    ),
  );
}

// ════════════════════════════════════════════════════════════════
// PLAN CARD
// ════════════════════════════════════════════════════════════════
class _Card extends StatelessWidget {
  final Map<String,dynamic> plan;
  final bool annual;
  const _Card({required this.plan, required this.annual});
  @override
  Widget build(BuildContext context) {
    final price     = annual ? plan['annual'] as int : plan['monthly'] as int;
    final isPopular = plan['popular'] as bool;
    final color     = Color(plan['color'] as int);
    final features  = plan['features'] as List;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isPopular ? color : Colors.grey[200]!, width: isPopular ? 2.5 : 1),
        boxShadow: [BoxShadow(
          color: isPopular ? color.withOpacity(0.15) : Colors.black.withOpacity(0.07),
          blurRadius: isPopular ? 20 : 8, offset: const Offset(0,4))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isPopular ? color : color.withOpacity(0.07),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14))),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (isPopular) Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
              child: const Text('⭐ MOST POPULAR', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
            Text(plan['name'] as String, style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: isPopular ? Colors.white : color)),
            Text(plan['tagline'] as String, style: TextStyle(fontSize: 11, color: isPopular ? Colors.white70 : Colors.grey[500])),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text('\$$price', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900,
                  color: isPopular ? Colors.white : const Color(0xFF1A1A1A), height: 1)),
              Padding(padding: const EdgeInsets.only(bottom:4,left:2),
                  child: Text('/mo', style: TextStyle(fontSize: 12, color: isPopular ? Colors.white70 : Colors.grey[500]))),
            ]),
            if (annual) Text('Billed \$${price*12}/year',
                style: TextStyle(fontSize: 10, color: isPopular ? Colors.white60 : Colors.grey[400])),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            ...features.map((f) {
              final row = f as List;
              final included = row[2] as bool;
              return Padding(padding: const EdgeInsets.only(bottom:8), child: Row(children: [
                Container(width:18,height:18,
                  decoration: BoxDecoration(color: included?color.withOpacity(0.1):Colors.grey[100], shape:BoxShape.circle),
                  child: Icon(included?Icons.check:Icons.close, size:11, color: included?color:Colors.grey[400])),
                const SizedBox(width:8),
                Expanded(child: Text(row[0] as String, style: TextStyle(fontSize:12, color:included?const Color(0xFF333333):Colors.grey[400]))),
                if ((row[1] as String).isNotEmpty)
                  Text(row[1] as String, style: TextStyle(fontSize:11, color:color, fontWeight:FontWeight.w600)),
              ]));
            }),
            const SizedBox(height:12),
            SizedBox(width: double.infinity, child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPopular?color:Colors.white,
                foregroundColor: isPopular?Colors.white:color,
                padding: const EdgeInsets.symmetric(vertical:12), elevation: isPopular?2:0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: isPopular?BorderSide.none:BorderSide(color:color,width:1.5)),
              ),
              child: const Text('Start Free Trial', style: TextStyle(fontWeight:FontWeight.w700, fontSize:13)),
            )),
          ]),
        ),
      ]),
    );
  }
}
