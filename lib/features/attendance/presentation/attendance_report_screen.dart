// lib/features/attendance/presentation/attendance_report_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/attendance_model.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/attendance_service.dart';
import '../../../core/services/employee_service.dart';

class AttendanceReportScreen extends StatefulWidget {
  final String businessId;
  const AttendanceReportScreen({super.key, required this.businessId});

  @override
  State<AttendanceReportScreen> createState() => _AttendanceReportScreenState();
}

class _AttendanceReportScreenState extends State<AttendanceReportScreen> {
  final _attendanceService = AttendanceService();
  final _employeeService = EmployeeService();

  DateTime _selectedMonth = DateTime.now();
  EmployeeModel? _selectedEmployee;
  List<EmployeeModel> _employees = [];
  Map<String, dynamic> _summary = {};
  List<AttendanceModel> _records = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees = await _employeeService
        .streamActiveEmployees(widget.businessId)
        .first;
    setState(() => _employees = employees);
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() => _isLoading = true);
    try {
      final from = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
      final to = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);

      final summary = await _attendanceService.getAttendanceSummary(
        businessId: widget.businessId,
        from: from,
        to: to,
        employeeId: _selectedEmployee?.id,
      );

      List<AttendanceModel> records = [];
      if (_selectedEmployee != null) {
        records = await _attendanceService.getMonthlyAttendance(
          businessId: widget.businessId,
          employeeId: _selectedEmployee!.id,
          month: _selectedMonth,
        );
        records.sort((a, b) => b.date.compareTo(a.date));
      }

      if (mounted) {
        setState(() {
          _summary = summary;
          _records = records;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Attendance Report'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filters
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Filters',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 12),
                    // Month picker
                    Row(children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _pickMonth,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(children: [
                              Icon(Icons.calendar_month, color: Colors.orange[700], size: 18),
                              const SizedBox(width: 8),
                              Text(DateFormat('MMMM yyyy').format(_selectedMonth),
                                  style: const TextStyle(fontWeight: FontWeight.w600)),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Prev/Next month
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() => _selectedMonth =
                              DateTime(_selectedMonth.year, _selectedMonth.month - 1));
                          _loadReport();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: _selectedMonth.month == DateTime.now().month &&
                                _selectedMonth.year == DateTime.now().year
                            ? null
                            : () {
                                setState(() => _selectedMonth =
                                    DateTime(_selectedMonth.year, _selectedMonth.month + 1));
                                _loadReport();
                              },
                      ),
                    ]),
                    const SizedBox(height: 10),
                    // Employee filter
                    DropdownButtonFormField<EmployeeModel?>(
                      value: _selectedEmployee,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.grey[100],
                        hintText: 'All Employees',
                        prefixIcon: Icon(Icons.person_outline,
                            color: Colors.grey[400], size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      ),
                      items: [
                        const DropdownMenuItem<EmployeeModel?>(
                          value: null,
                          child: Text('All Employees'),
                        ),
                        ..._employees.map((e) => DropdownMenuItem<EmployeeModel?>(
                              value: e,
                              child: Text(e.fullName),
                            )),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedEmployee = v);
                        _loadReport();
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else ...[
              // Summary
              const Text('Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _statCard('Present', _summary['present'] ?? 0, Colors.green)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Absent', _summary['absent'] ?? 0, Colors.red)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Late', _summary['late'] ?? 0, Colors.orange)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: _statCard('Half Day', _summary['halfDay'] ?? 0, Colors.blue)),
                const SizedBox(width: 8),
                Expanded(child: _statCard('Leave', _summary['leave'] ?? 0, Colors.purple)),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
                    ),
                    child: Column(children: [
                      Text(
                        '${((_summary['totalMinutes'] ?? 0) / 60).toStringAsFixed(1)}h',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Colors.teal[700]),
                      ),
                      Text('Total Hrs',
                          style: TextStyle(color: Colors.grey[600], fontSize: 10),
                          textAlign: TextAlign.center),
                    ]),
                  ),
                ),
              ]),

              // Records (if employee selected)
              if (_selectedEmployee != null && _records.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text('${_selectedEmployee!.fullName} — ${DateFormat('MMMM').format(_selectedMonth)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 12),
                ..._records.map((r) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _statusColor(r.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(r.date.split('-').last,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _statusColor(r.status))),
                          ),
                        ),
                        title: Text(r.statusLabel,
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _statusColor(r.status),
                                fontSize: 14)),
                        subtitle: Text(
                          '${r.formattedCheckIn} → ${r.formattedCheckOut}',
                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                        ),
                        trailing: r.workedMinutes != null
                            ? Text(r.formattedWorkedHours,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal[700],
                                    fontSize: 13))
                            : null,
                      ),
                    )),
              ],
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4)],
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: color)),
        Text(label,
            style: TextStyle(color: Colors.grey[600], fontSize: 10),
            textAlign: TextAlign.center),
      ]),
    );
  }

  Future<void> _pickMonth() async {
    final now = DateTime.now();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Select Month'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: ListView.builder(
            itemCount: 12,
            itemBuilder: (_, i) {
              final month = DateTime(now.year, now.month - i);
              return ListTile(
                title: Text(DateFormat('MMMM yyyy').format(month)),
                selected: month.month == _selectedMonth.month &&
                    month.year == _selectedMonth.year,
                selectedColor: Colors.orange[700],
                onTap: () {
                  setState(() => _selectedMonth = month);
                  Navigator.pop(context);
                  _loadReport();
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
