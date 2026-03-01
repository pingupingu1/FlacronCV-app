// lib/features/bookings/presentation/create_booking_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/service_model.dart';
import '../../../core/models/booking_model.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/services/business_service.dart';

class CreateBookingScreen extends StatefulWidget {
  final String businessId;
  final DateTime? initialDate;
  const CreateBookingScreen({
    super.key,
    required this.businessId,
    this.initialDate,
  });

  @override
  State<CreateBookingScreen> createState() => _CreateBookingScreenState();
}

class _CreateBookingScreenState extends State<CreateBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bookingService = BookingService();
  final _businessService = BusinessService();

  // Form controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  // State
  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  DateTime _selectedDate = DateTime.now();
  String? _selectedSlot;
  List<String> _availableSlots = [];
  List<String> _bookedSlots = [];
  bool _isLoading = false;
  bool _isLoadingSlots = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (widget.initialDate != null) _selectedDate = widget.initialDate!;
    _loadServices();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadServices() async {
    try {
      final services =
          await _businessService.getServices(widget.businessId);
      setState(() => _services = services);
      if (services.isNotEmpty) {
        _selectedService = services.first;
        await _loadSlots();
      }
    } catch (e) {
      debugPrint('Error loading services: $e');
    }
  }

  Future<void> _loadSlots() async {
    if (_selectedService == null) return;
    setState(() {
      _isLoadingSlots = true;
      _selectedSlot = null;
    });
    try {
      // Get booked slots
      _bookedSlots = await _bookingService.getBookedSlots(
          widget.businessId, _selectedDate);

      // Get business hours for selected day
      final hours = await _businessService
          .getBusinessHours(widget.businessId);
      final dayIndex = _selectedDate.weekday - 1; // 0=Mon
      final dayHours = hours?.getDayByIndex(dayIndex);

      if (dayHours == null || !dayHours.isOpen) {
        setState(() {
          _availableSlots = [];
          _isLoadingSlots = false;
        });
        return;
      }

      final allSlots = _bookingService.generateTimeSlots(
        openTime: dayHours.openTime,
        closeTime: dayHours.closeTime,
        durationMinutes: _selectedService!.durationMinutes,
      );

      setState(() {
        _availableSlots = allSlots;
        _isLoadingSlots = false;
      });
    } catch (e) {
      debugPrint('Error loading slots: $e');
      // Fallback: generate default slots 9am-5pm
      final allSlots = _bookingService.generateTimeSlots(
        openTime: '09:00',
        closeTime: '17:00',
        durationMinutes: _selectedService?.durationMinutes ?? 60,
      );
      setState(() {
        _availableSlots = allSlots;
        _isLoadingSlots = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.orange[700]!,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      await _loadSlots();
    }
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedService == null) {
      setState(() => _errorMessage = 'Please select a service');
      return;
    }
    if (_selectedSlot == null) {
      setState(() => _errorMessage = 'Please select a time slot');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _bookingService.createBooking(
        businessId: widget.businessId,
        serviceId: _selectedService!.id,
        serviceName: _selectedService!.name,
        servicePrice: _selectedService!.price,
        serviceDurationMinutes: _selectedService!.durationMinutes,
        customerName: _nameCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim().isEmpty
            ? null
            : _emailCtrl.text.trim(),
        date: _selectedDate,
        timeSlot: _selectedSlot!,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Booking created successfully! ✅'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Error ──
              if (_errorMessage != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline,
                          color: Colors.red[700], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_errorMessage!,
                            style: TextStyle(
                                color: Colors.red[700], fontSize: 14)),
                      ),
                    ],
                  ),
                ),

              // ─────────────────────────
              // SECTION 1: Service
              // ─────────────────────────
              _sectionTitle('Select Service', Icons.spa_outlined),
              const SizedBox(height: 8),
              if (_services.isEmpty)
                const Center(child: CircularProgressIndicator(color: Colors.orange))
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _services.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (ctx, i) {
                      final s = _services[i];
                      final isSelected = _selectedService?.id == s.id;
                      return GestureDetector(
                        onTap: () async {
                          setState(() => _selectedService = s);
                          await _loadSlots();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 140,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.orange[700]
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.orange[700]!
                                  : Colors.grey[300]!,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                        color: Colors.orange.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4))
                                  ]
                                : [],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(s.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.black87,
                                      fontSize: 13),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text(s.formattedPrice,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white70
                                          : Colors.orange[700],
                                      fontWeight: FontWeight.bold)),
                              Text(s.formattedDuration,
                                  style: TextStyle(
                                      color: isSelected
                                          ? Colors.white60
                                          : Colors.grey[600],
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              // ─────────────────────────
              // SECTION 2: Date
              // ─────────────────────────
              _sectionTitle('Select Date', Icons.calendar_today_outlined),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[300]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_month,
                          color: Colors.orange[700]),
                      const SizedBox(width: 12),
                      Text(
                        _formatDate(_selectedDate),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_drop_down,
                          color: Colors.grey[600]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ─────────────────────────
              // SECTION 3: Time slots
              // ─────────────────────────
              _sectionTitle('Select Time', Icons.access_time_outlined),
              const SizedBox(height: 8),
              if (_isLoadingSlots)
                const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
              else if (_availableSlots.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.block, color: Colors.red[400]),
                      const SizedBox(width: 8),
                      Text('Business is closed on this day',
                          style: TextStyle(color: Colors.red[700])),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _availableSlots.map((slot) {
                    final isBooked = _bookedSlots.contains(slot);
                    final isSelected = _selectedSlot == slot;
                    return GestureDetector(
                      onTap: isBooked
                          ? null
                          : () => setState(() => _selectedSlot = slot),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isBooked
                              ? Colors.grey[100]
                              : isSelected
                                  ? Colors.orange[700]
                                  : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isBooked
                                ? Colors.grey[300]!
                                : isSelected
                                    ? Colors.orange[700]!
                                    : Colors.orange[300]!,
                          ),
                        ),
                        child: Text(
                          _bookingService.formatTo12h(slot),
                          style: TextStyle(
                            color: isBooked
                                ? Colors.grey[400]
                                : isSelected
                                    ? Colors.white
                                    : Colors.orange[800],
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: isBooked
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              const SizedBox(height: 20),

              // ─────────────────────────
              // SECTION 4: Customer Info
              // ─────────────────────────
              _sectionTitle('Customer Details', Icons.person_outline),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                textInputAction: TextInputAction.next,
                decoration: _dec('Full Name', Icons.person_outline),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: _dec('Phone Number', Icons.phone_outlined),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration:
                    _dec('Email (Optional)', Icons.email_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 2,
                decoration:
                    _dec('Notes (Optional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 24),

              // ─────────────────────────
              // Summary card
              // ─────────────────────────
              if (_selectedService != null && _selectedSlot != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Booking Summary',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800])),
                      const SizedBox(height: 8),
                      _summaryRow('Service', _selectedService!.name),
                      _summaryRow('Date', _formatDate(_selectedDate)),
                      _summaryRow('Time',
                          _bookingService.formatTo12h(_selectedSlot!)),
                      _summaryRow('Duration',
                          _selectedService!.formattedDuration),
                      _summaryRow('Price', _selectedService!.formattedPrice),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // ─────────────────────────
              // Submit button
              // ─────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  icon: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _isLoading ? 'Creating...' : 'Confirm Booking',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.orange[700], size: 20),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text('$label: ',
              style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun',
                    'Jul','Aug','Sep','Oct','Nov','Dec'];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.orange[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      );
}