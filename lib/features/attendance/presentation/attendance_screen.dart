// lib/features/attendance/presentation/attendance_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/employee_service.dart';
import 'clock_in_screen.dart';
import 'attendance_report_screen.dart';

class AttendanceScreen extends StatefulWidget {
  final String businessId;
  const AttendanceScreen({super.key, required this.businessId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  final _attendanceService = AttendanceService();
  final _employeeService = EmployeeService();
  late TabController _tabController;

  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic> _todaySummary = {};
  bool _loadingSummary = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadSummary();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _loadingSummary = true);
    try {
      final s = await _attendanceService.getAttendanceSummary(
        businessId: widget.businessId,
        from: _selectedDate,
        to: _selectedDate,
      );
      if (mounted) setState(() { _todaySummary = s; _loadingSummary = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingSummary = false);
    }
  }

  Color _statusColor(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return Colors.green;
      case AttendanceStatus.absent:  return Colors.red;
      case AttendanceStatus.late:    return Colors.orange;
      case AttendanceStatus.halfDay: return Colors.blue;
      case AttendanceStatus.leave:   return Colors.purple;
    }
  }

  IconData _statusIcon(AttendanceStatus s) {
    switch (s) {
      case AttendanceStatus.present: return Icons.check_circle_outline;
      case AttendanceStatus.absent:  return Icons.cancel_outlined;
      case AttendanceStatus.late:    return Icons.schedule;
      case AttendanceStatus.halfDay: return Icons.timelapse;
      case AttendanceStatus.leave:   return Icons.beach_access_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.assessment_outlined),
            tooltip: 'Reports',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AttendanceReportScreen(
                    businessId: widget.businessId),
              ),
            ),
          ),
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadSummary),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Today', icon: Icon(Icons.today, size: 18)),
            Tab(text: 'Clock In/Out', icon: Icon(Icons.fingerprint, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTodayTab(),
          _buildClockInTab(),
        ],
      ),
    );
  }

  // ─── Today Tab ───────────────────────────────────────────────
  Widget _buildTodayTab() {
    return RefreshIndicator(
      onRefresh: _loadSummary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Date header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _selectedDate,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                        builder: (ctx, child) => Theme(
                          data: Theme.of(ctx).copyWith(
                            colorScheme: ColorScheme.light(primary: Colors.orange[700]!),
                          ),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedDate = picked);
                        _loadSummary();
                      }
                    },
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: Colors.orange[700], size: 18),
                      const SizedBox(width: 8),
                      Text(
                        DateFormat('EEEE, MMMM d').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.grey[400]),
                    ]),
                  ),
                  if (!_isSameDay(_selectedDate, DateTime.now()))
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedDate = DateTime.now());
                        _loadSummary();
                      },
                      child: Text('Today', style: TextStyle(color: Colors.orange[700])),
                    ),
                ],
              ),
            ),

            // Summary cards
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(children: [
                    Expanded(child: _summaryCard('Present',
                        _todaySummary['present'] ?? 0, Colors.green, Icons.check_circle_outline)),
                    const SizedBox(width: 10),
                    Expanded(child: _summaryCard('Absent',
                        _todaySummary['absent'] ?? 0, Colors.red, Icons.cancel_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _summaryCard('Late',
                        _todaySummary['late'] ?? 0, Colors.orange, Icons.schedule)),
                  ]),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(child: _summaryCard('Half Day',
                        _todaySummary['halfDay'] ?? 0, Colors.blue, Icons.timelapse)),
                    const SizedBox(width: 10),
                    Expanded(child: _summaryCard('Leave',
                        _todaySummary['leave'] ?? 0, Colors.purple, Icons.beach_access_outlined)),
                    const SizedBox(width: 10),
                    Expanded(child: _summaryCard('Total',
                        _todaySummary['total'] ?? 0, Colors.grey, Icons.people_outline)),
                  ]),
                ],
              ),
            ),

            // Attendance list
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Attendance Records',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  TextButton.icon(
                    onPressed: () => _showMarkAttendanceDialog(),
                    icon: Icon(Icons.add, color: Colors.orange[700], size: 16),
                    label: Text('Mark', style: TextStyle(color: Colors.orange[700])),
                  ),
                ],
              ),
            ),

            StreamBuilder<List<AttendanceModel>>(
              stream: _attendanceService.streamAttendanceForDate(
                businessId: widget.businessId,
                date: _selectedDate,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final records = snap.data ?? [];
                if (records.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Center(
                      child: Column(children: [
                        Icon(Icons.event_available, size: 56, color: Colors.grey[300]),
                        const SizedBox(height: 12),
                        Text('No attendance records for this day',
                            style: TextStyle(color: Colors.grey[500])),
                      ]),
                    ),
                  );
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: records.length,
                  itemBuilder: (_, i) => _attendanceCard(records[i]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(_loadingSummary ? '-' : '$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Widget _attendanceCard(AttendanceModel record) {
    final color = _statusColor(record.status);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(children: [
          // Status indicator
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_statusIcon(record.status), color: color, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(record.employeeName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 3),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6)),
                  child: Text(record.statusLabel,
                      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: 8),
                if (record.workedMinutes != null)
                  Text(record.formattedWorkedHours,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
              ]),
            ]),
          ),
          // Times
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Row(children: [
              Icon(Icons.login, size: 12, color: Colors.green[600]),
              const SizedBox(width: 4),
              Text(record.formattedCheckIn,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.logout, size: 12, color: Colors.red[400]),
              const SizedBox(width: 4),
              Text(record.formattedCheckOut,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            ]),
          ]),
        ]),
      ),
    );
  }

  // ─── Clock In/Out Tab ────────────────────────────────────────
  Widget _buildClockInTab() {
    return StreamBuilder<List<EmployeeModel>>(
      stream: _employeeService.streamActiveEmployees(widget.businessId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final employees = snap.data ?? [];
        if (employees.isEmpty) {
          return Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.people_outline, size: 72, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('No active employees',
                  style: TextStyle(fontSize: 17, color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('Add employees first', style: TextStyle(color: Colors.grey[500])),
            ]),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          itemCount: employees.length,
          itemBuilder: (_, i) => _clockInCard(employees[i]),
        );
      },
    );
  }

  Widget _clockInCard(EmployeeModel employee) {
    return FutureBuilder<AttendanceModel?>(
      future: _attendanceService.getAttendanceForEmployee(
        businessId: widget.businessId,
        employeeId: employee.id,
        date: DateTime.now(),
      ),
      builder: (context, snap) {
        final record = snap.data;
        final isClockedIn = record?.isClockedIn ?? false;
        final isDone = record?.checkOutTime != null;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              // Avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(employee.initials,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.orange[700])),
                ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(employee.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  Text(employee.position,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  if (record != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      Icon(Icons.login, size: 12, color: Colors.green[600]),
                      const SizedBox(width: 4),
                      Text('In: ${record.formattedCheckIn}',
                          style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      if (record.checkOutTime != null) ...[
                        const SizedBox(width: 8),
                        Icon(Icons.logout, size: 12, color: Colors.red[400]),
                        const SizedBox(width: 4),
                        Text('Out: ${record.formattedCheckOut}',
                            style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ]),
                  ],
                ]),
              ),
              // Clock button
              if (isDone)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.check, color: Colors.green[700], size: 14),
                    const SizedBox(width: 4),
                    Text(record!.formattedWorkedHours,
                        style: TextStyle(
                            color: Colors.green[700],
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ]),
                )
              else
                ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ClockInScreen(
                        businessId: widget.businessId,
                        employee: employee,
                        existingRecord: record,
                      ),
                    ),
                  ).then((_) => setState(() {})),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isClockedIn ? Colors.red[600] : Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    isClockedIn ? 'Clock Out' : 'Clock In',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
            ]),
          ),
        );
      },
    );
  }

  // ─── Mark Attendance Dialog ──────────────────────────────────
  Future<void> _showMarkAttendanceDialog() async {
    final employees = await _employeeService
        .streamActiveEmployees(widget.businessId)
        .first;
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) => _MarkAttendanceDialog(
        employees: employees,
        date: _selectedDate,
        businessId: widget.businessId,
        attendanceService: _attendanceService,
        onSaved: _loadSummary,
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─── Mark Attendance Dialog Widget ───────────────────────────────
class _MarkAttendanceDialog extends StatefulWidget {
  final List<EmployeeModel> employees;
  final DateTime date;
  final String businessId;
  final AttendanceService attendanceService;
  final VoidCallback onSaved;

  const _MarkAttendanceDialog({
    required this.employees,
    required this.date,
    required this.businessId,
    required this.attendanceService,
    required this.onSaved,
  });

  @override
  State<_MarkAttendanceDialog> createState() => _MarkAttendanceDialogState();
}

class _MarkAttendanceDialogState extends State<_MarkAttendanceDialog> {
  EmployeeModel? _selectedEmployee;
  AttendanceStatus _status = AttendanceStatus.present;
  final _notesCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Mark Attendance'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Employee picker
          DropdownButtonFormField<EmployeeModel>(
            value: _selectedEmployee,
            hint: const Text('Select Employee'),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
            items: widget.employees.map((e) => DropdownMenuItem(
              value: e,
              child: Text(e.fullName),
            )).toList(),
            onChanged: (v) => setState(() => _selectedEmployee = v),
          ),
          const SizedBox(height: 16),
          // Status selector
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: AttendanceStatus.values.map((s) {
              final selected = _status == s;
              final colors = {
                AttendanceStatus.present: Colors.green,
                AttendanceStatus.absent: Colors.red,
                AttendanceStatus.late: Colors.orange,
                AttendanceStatus.halfDay: Colors.blue,
                AttendanceStatus.leave: Colors.purple,
              };
              final color = colors[s]!;
              return GestureDetector(
                onTap: () => setState(() => _status = s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? color : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? color : Colors.grey[300]!),
                  ),
                  child: Text(
                    s.name[0].toUpperCase() + s.name.substring(1),
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[700],
                        fontSize: 12,
                        fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            decoration: InputDecoration(
              hintText: 'Notes (optional)',
              filled: true,
              fillColor: Colors.grey[100],
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading || _selectedEmployee == null ? null : () async {
            setState(() => _isLoading = true);
            await widget.attendanceService.markAttendance(
              businessId: widget.businessId,
              employeeId: _selectedEmployee!.id,
              employeeName: _selectedEmployee!.fullName,
              date: widget.date,
              status: _status,
              notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
            );
            widget.onSaved();
            if (mounted) Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(width: 16, height: 16,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
