// lib/features/attendance/presentation/clock_in_screen.dart

import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/attendance_service.dart';

class ClockInScreen extends StatefulWidget {
  final String businessId;
  final EmployeeModel employee;
  final AttendanceModel? existingRecord;

  const ClockInScreen({
    super.key,
    required this.businessId,
    required this.employee,
    this.existingRecord,
  });

  @override
  State<ClockInScreen> createState() => _ClockInScreenState();
}

class _ClockInScreenState extends State<ClockInScreen> {
  final _attendanceService = AttendanceService();
  final _notesCtrl = TextEditingController();

  bool _isLoading = false;
  String? _error;
  late Timer _timer;
  DateTime _now = DateTime.now();

  bool get _isClockedIn => widget.existingRecord?.isClockedIn ?? false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _notesCtrl.dispose();
    super.dispose();
  }

  String get _timeString {
    final h = _now.hour;
    final m = _now.minute.toString().padLeft(2, '0');
    final s = _now.second.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m:$s $period';
  }

  String get _elapsed {
    if (widget.existingRecord?.checkInTime == null) return '';
    final diff = _now.difference(widget.existingRecord!.checkInTime!);
    final h = diff.inHours;
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return '${h}h ${m}m ${s}s';
  }

  Future<void> _clockIn() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _attendanceService.clockIn(
        businessId: widget.businessId,
        employeeId: widget.employee.id,
        employeeName: widget.employee.fullName,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.employee.fullName} clocked in ✓'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  Future<void> _clockOut() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _attendanceService.clockOut(
        businessId: widget.businessId,
        employeeId: widget.employee.id,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.employee.fullName} clocked out ✓'),
            backgroundColor: Colors.orange[700],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(_isClockedIn ? 'Clock Out' : 'Clock In'),
        backgroundColor: _isClockedIn ? Colors.red[600] : Colors.green[600],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Employee avatar
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(widget.employee.initials,
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700])),
              ),
            ),
            const SizedBox(height: 16),
            Text(widget.employee.fullName,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(widget.employee.position,
                style: TextStyle(color: Colors.grey[600], fontSize: 15)),

            const SizedBox(height: 32),

            // Live clock
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12),
                ],
              ),
              child: Column(children: [
                Text(_timeString,
                    style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: _isClockedIn ? Colors.red[600] : Colors.green[600],
                        fontFeatures: const []),
                    textAlign: TextAlign.center),
                if (_isClockedIn) ...[
                  const SizedBox(height: 8),
                  Text('Time worked: $_elapsed',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    'Clocked in at ${widget.existingRecord!.formattedCheckIn}',
                    style: TextStyle(color: Colors.grey[500], fontSize: 13),
                  ),
                ],
              ]),
            ),

            const SizedBox(height: 24),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(children: [
                  Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700]))),
                ]),
              ),

            // Notes field
            TextField(
              controller: _notesCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Notes (optional)',
                prefixIcon: Icon(Icons.notes, color: Colors.grey[400], size: 20),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[300]!)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: (_isClockedIn ? Colors.red[600] : Colors.green[600])!,
                        width: 2)),
              ),
            ),
            const SizedBox(height: 24),

            // Action button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : (_isClockedIn ? _clockOut : _clockIn),
                icon: _isLoading
                    ? const SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Icon(_isClockedIn ? Icons.logout : Icons.login, size: 22),
                label: Text(
                  _isLoading
                      ? 'Processing...'
                      : _isClockedIn
                          ? 'Clock Out Now'
                          : 'Clock In Now',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isClockedIn ? Colors.red[600] : Colors.green[600],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
