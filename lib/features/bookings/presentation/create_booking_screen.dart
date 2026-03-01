// lib/features/bookings/presentation/create_booking_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/business_service.dart';
import '../../../routes/route_names.dart';

class CreateBookingScreen extends StatefulWidget {
  final String? businessId;
  const CreateBookingScreen({super.key, this.businessId});

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _bookingService = BookingService();
  final _businessService = BusinessService();

  int _step = 0; // 0=service, 1=date/time, 2=details, 3=confirm
  bool _isLoading = false;
  String? _error;

  // Step 1: Service
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  bool _loadingServices = true;

  // Step 2: Date & Time
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String? _selectedTime;
  List<String> _availableSlots = [];
  bool _loadingSlots = false;

  // Step 3: Customer Details
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String? _businessId;

  @override
  void initState() {
    super.initState();
    _resolveBusinessId();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _resolveBusinessId() async {
    _businessId = widget.businessId;
    if (_businessId == null || _businessId!.isEmpty) {
      final biz = await _businessService.getMyBusiness();
      _businessId = biz?.id;
    }
    _loadServices();
  }

  Future<void> _loadServices() async {
    if (_businessId == null) return;
    final services = await _businessService.getServices(_businessId!);
    if (mounted) {
      setState(() {
        _services = services.where((s) => s.isActive).toList();
        _loadingServices = false;
      });
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedService == null || _businessId == null) return;
    setState(() { _loadingSlots = true; _selectedTime = null; });
    final slots = await _bookingService.getAvailableSlots(
      businessId: _businessId!,
      date: _selectedDate,
      durationMinutes: _selectedService!.durationMinutes,
    );
    if (mounted) setState(() { _availableSlots = slots; _loadingSlots = false; });
  }

  void _nextStep() {
    if (_step == 0 && _selectedService == null) {
      setState(() => _error = 'Please select a service');
      return;
    }
    if (_step == 1 && _selectedTime == null) {
      setState(() => _error = 'Please select a time slot');
      return;
    }
    if (_step == 2) {
      if (_nameCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Customer name is required');
        return;
      }
      if (_phoneCtrl.text.trim().isEmpty) {
        setState(() => _error = 'Phone number is required');
        return;
      }
    }
    setState(() { _error = null; _step++; });
    if (_step == 1) _loadSlots();
  }

  void _prevStep() {
    if (_step > 0) setState(() { _step--; _error = null; });
  }

  Future<void> _confirm() async {
    if (_businessId == null || _selectedService == null || _selectedTime == null) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await _bookingService.createBooking(
        businessId: _businessId!,
        serviceId: _selectedService!.id,
        serviceName: _selectedService!.name,
        servicePrice: _selectedService!.price,
        serviceDurationMinutes: _selectedService!.durationMinutes,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        date: _selectedDate,
        timeSlot: _selectedTime!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Booking created successfully! ✓'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('New Booking'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_step + 1) / 4,
            backgroundColor: Colors.orange[400],
            valueColor: const AlwaysStoppedAnimation(Colors.white),
            minHeight: 4,
          ),
        ),
      ),
      body: Column(
        children: [
          // Step indicator
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stepChip(0, 'Service'),
                _stepLine(0),
                _stepChip(1, 'Date & Time'),
                _stepLine(1),
                _stepChip(2, 'Details'),
                _stepLine(2),
                _stepChip(3, 'Confirm'),
              ],
            ),
          ),

          // Error
          if (_error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              color: Colors.red[50],
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
              ]),
            ),

          // Content
          Expanded(
            child: [
              _buildStep0(),
              _buildStep1(),
              _buildStep2(),
              _buildStep3(),
            ][_step],
          ),

          // Nav buttons
          _buildNavBar(),
        ],
      ),
    );
  }

  // ─── Step 0: Select Service ──────────────────────────────────
  Widget _buildStep0() {
    if (_loadingServices) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_cut_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('No services found',
                style: TextStyle(color: Colors.grey[600], fontSize: 16)),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pushNamed(
                  context, RouteNames.services,
                  arguments: {'businessId': _businessId}),
              child: const Text('Add Services First'),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _services.length,
      itemBuilder: (_, i) {
        final s = _services[i];
        final selected = _selectedService?.id == s.id;
        return GestureDetector(
          onTap: () => setState(() { _selectedService = s; _error = null; }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: selected ? Colors.orange[700]! : Colors.grey[200]!,
                  width: selected ? 2 : 1),
              boxShadow: selected
                  ? [BoxShadow(color: Colors.orange.withValues(alpha: 0.15), blurRadius: 8)]
                  : [],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: selected ? Colors.orange[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.content_cut,
                    color: selected ? Colors.orange[700] : Colors.grey[500],
                    size: 22),
              ),
              title: Text(s.name,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: selected ? Colors.orange[700] : Colors.black)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.access_time, size: 13, color: Colors.grey[500]),
                    const SizedBox(width: 4),
                    Text(s.formattedDuration,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ]),
                  if (s.description != null && s.description!.isNotEmpty)
                    Text(s.description!,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(s.formattedPrice,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: selected ? Colors.orange[700] : Colors.black)),
                  if (selected)
                    Icon(Icons.check_circle, color: Colors.orange[700], size: 18),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Step 1: Date & Time ─────────────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date picker
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: CalendarDatePicker(
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 180)),
                onDateChanged: (date) {
                  setState(() => _selectedDate = date);
                  _loadSlots();
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Available Times — ${DateFormat('EEE, MMM d').format(_selectedDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          if (_loadingSlots)
            const Center(child: CircularProgressIndicator())
          else if (_availableSlots.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: Row(children: [
                Icon(Icons.info_outline, color: Colors.orange[700]),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('No available slots for this day. Try another date.',
                      style: TextStyle(fontSize: 13)),
                ),
              ]),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableSlots.map((slot) {
                final sel = _selectedTime == slot;
                return GestureDetector(
                  onTap: () => setState(() { _selectedTime = slot; _error = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: sel ? Colors.orange[700] : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: sel ? Colors.orange[700]! : Colors.grey[300]!),
                    ),
                    child: Text(
                      _bookingService.formatTime(slot),
                      style: TextStyle(
                          color: sel ? Colors.white : Colors.grey[800],
                          fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  // ─── Step 2: Customer Details ────────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👤', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('Customer Information',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Who is this booking for?',
              style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          const SizedBox(height: 24),
          _detailField(_nameCtrl, 'Full Name *', Icons.person_outline),
          _detailField(_phoneCtrl, 'Phone Number *', Icons.phone_outlined,
              type: TextInputType.phone),
          _detailField(_emailCtrl, 'Email (optional)', Icons.email_outlined,
              type: TextInputType.emailAddress),
          _detailField(_notesCtrl, 'Notes (optional)', Icons.notes_outlined,
              maxLines: 3),
        ],
      ),
    );
  }

  // ─── Step 3: Confirm ─────────────────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('✅', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          const Text('Confirm Booking',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          // Summary card
          Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _summaryRow(Icons.content_cut, 'Service',
                      _selectedService?.name ?? ''),
                  _summaryRow(Icons.attach_money, 'Price',
                      _selectedService?.formattedPrice ?? ''),
                  _summaryRow(Icons.access_time, 'Duration',
                      _selectedService?.formattedDuration ?? ''),
                  const Divider(height: 24),
                  _summaryRow(Icons.calendar_today, 'Date',
                      DateFormat('EEEE, MMMM d, y').format(_selectedDate)),
                  _summaryRow(Icons.schedule, 'Time',
                      _selectedTime != null
                          ? _bookingService.formatTime(_selectedTime!)
                          : ''),
                  const Divider(height: 24),
                  _summaryRow(Icons.person, 'Customer', _nameCtrl.text),
                  _summaryRow(Icons.phone, 'Phone', _phoneCtrl.text),
                  if (_emailCtrl.text.isNotEmpty)
                    _summaryRow(Icons.email, 'Email', _emailCtrl.text),
                  if (_notesCtrl.text.isNotEmpty)
                    _summaryRow(Icons.notes, 'Notes', _notesCtrl.text),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 18),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Booking will be set to Pending status. Confirm it afterward from the booking detail.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.orange[700]),
        const SizedBox(width: 10),
        Text('$label:',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13, color: Colors.grey)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }

  Widget _detailField(
      TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
      ),
    );
  }

  Widget _stepChip(int step, String label) {
    final isActive = _step == step;
    final isDone = _step > step;
    return Column(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isDone
                ? Colors.green
                : isActive
                    ? Colors.orange[700]
                    : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 14)
                : Text('${step + 1}',
                    style: TextStyle(
                        color: isActive ? Colors.white : Colors.grey[600],
                        fontSize: 12,
                        fontWeight: FontWeight.bold)),
          ),
        ),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 9,
                color: isActive ? Colors.orange[700] : Colors.grey[500],
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _stepLine(int afterStep) {
    final isDone = _step > afterStep;
    return Container(
      width: 30,
      height: 2,
      margin: const EdgeInsets.only(bottom: 18),
      color: isDone ? Colors.green : Colors.grey[300],
    );
  }

  Widget _buildNavBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3))
        ],
      ),
      child: Row(
        children: [
          if (_step > 0)
            Expanded(
              child: OutlinedButton(
                onPressed: _prevStep,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back',
                    style: TextStyle(
                        color: Colors.grey, fontWeight: FontWeight.w600)),
              ),
            ),
          if (_step > 0) const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _isLoading
                  ? null
                  : _step == 3
                      ? _confirm
                      : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: _step == 3 ? Colors.green[600] : Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : Text(
                      _step == 3 ? 'Confirm Booking ✓' : 'Continue',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
