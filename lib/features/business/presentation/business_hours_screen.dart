// lib/features/business/presentation/business_hours_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/business_hours_model.dart';
import '../../../core/services/business_service.dart';

class BusinessHoursScreen extends StatefulWidget {
  final String businessId;
  const BusinessHoursScreen({super.key, required this.businessId});

  @override
  State<BusinessHoursScreen> createState() => _BusinessHoursScreenState();
}

class _BusinessHoursScreenState extends State<BusinessHoursScreen> {
  final _businessService = BusinessService();
  BusinessHoursModel? _hours;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final hours = await _businessService.getBusinessHours(widget.businessId);
    if (mounted) setState(() { _hours = hours; _isLoading = false; });
  }

  Future<void> _save() async {
    if (_hours == null) return;
    setState(() => _isSaving = true);
    try {
      await _businessService.saveBusinessHours(widget.businessId, _hours!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Business hours saved!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickTime(String dayName, bool isOpen) async {
    if (_hours == null) return;
    final day = _hours!.days.firstWhere((d) => d.key == dayName).value;
    final initialTime = _parseTime(isOpen ? day.openTime : day.closeTime);

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.orange[700]!,
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );

    if (picked != null) {
      final timeStr =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      final updated = day.copyWith(
        openTime: isOpen ? timeStr : day.openTime,
        closeTime: isOpen ? day.closeTime : timeStr,
      );
      setState(() => _hours = _hours!.updateDay(dayName, updated));
    }
  }

  TimeOfDay _parseTime(String t) {
    final parts = t.split(':');
    return TimeOfDay(
        hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTime(String t) {
    final parts = t.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:${m.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Business Hours'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.info_outline,
                        color: Colors.orange[700], size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Set your opening hours. These are used to show availability when customers book appointments.',
                        style: TextStyle(
                            color: Colors.orange[800],
                            fontSize: 13,
                            height: 1.4),
                      ),
                    ),
                  ]),
                ),

                // Days list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _hours!.days.length,
                    itemBuilder: (context, index) {
                      final entry = _hours!.days[index];
                      final dayName = entry.key;
                      final day = entry.value;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(dayName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 15)),
                                  Row(children: [
                                    Text(
                                      day.isOpen ? 'Open' : 'Closed',
                                      style: TextStyle(
                                          color: day.isOpen
                                              ? Colors.green[600]
                                              : Colors.grey[500],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 13),
                                    ),
                                    const SizedBox(width: 8),
                                    Switch(
                                      value: day.isOpen,
                                      onChanged: (v) {
                                        setState(() {
                                          _hours = _hours!.updateDay(
                                              dayName,
                                              day.copyWith(isOpen: v));
                                        });
                                      },
                                      activeColor: Colors.orange[700],
                                    ),
                                  ]),
                                ],
                              ),
                              if (day.isOpen) ...[
                                const SizedBox(height: 12),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _timeTile(
                                        'Opens',
                                        _formatTime(day.openTime),
                                        () => _pickTime(dayName, true),
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 12),
                                      child: Icon(Icons.arrow_forward,
                                          color: Colors.grey[400], size: 18),
                                    ),
                                    Expanded(
                                      child: _timeTile(
                                        'Closes',
                                        _formatTime(day.closeTime),
                                        () => _pickTime(dayName, false),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Save button
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Save Business Hours',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _timeTile(String label, String time, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(time,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
