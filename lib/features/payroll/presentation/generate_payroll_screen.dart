// lib/features/payroll/presentation/generate_payroll_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/payroll_service.dart';
import '../../../core/services/employee_service.dart';

class GeneratePayrollScreen extends StatefulWidget {
  final String businessId;
  const GeneratePayrollScreen({super.key, required this.businessId});

  @override
  State<GeneratePayrollScreen> createState() => _GeneratePayrollScreenState();
}

class _GeneratePayrollScreenState extends State<GeneratePayrollScreen> {
  final _payrollService = PayrollService();
  final _employeeService = EmployeeService();

  List<EmployeeModel> _employees = [];
  Set<String> _selectedIds = {};
  bool _selectAll = true;

  DateTime _periodStart = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _periodEnd = DateTime(
      DateTime.now().year, DateTime.now().month + 1, 0);

  double _deductionRate = 0.15;
  bool _isLoading = false;
  bool _loadingEmployees = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEmployees();
  }

  Future<void> _loadEmployees() async {
    final employees =
        await _employeeService.streamActiveEmployees(widget.businessId).first;
    setState(() {
      _employees = employees;
      _selectedIds = employees.map((e) => e.id).toSet();
      _loadingEmployees = false;
    });
  }

  Future<void> _pickDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _periodStart : _periodEnd,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.orange[700]!),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) _periodStart = picked;
        else _periodEnd = picked;
      });
    }
  }

  Future<void> _generate() async {
    if (_selectedIds.isEmpty) {
      setState(() => _error = 'Select at least one employee');
      return;
    }
    if (_periodStart.isAfter(_periodEnd)) {
      setState(() => _error = 'Start date must be before end date');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final selectedEmployees =
          _employees.where((e) => _selectedIds.contains(e.id)).toList();

      await _payrollService.generatePayrollForAll(
        businessId: widget.businessId,
        employees: selectedEmployees,
        periodStart: _periodStart,
        periodEnd: _periodEnd,
        deductionRate: _deductionRate,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Payroll generated for ${selectedEmployees.length} employee(s) ✓'),
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
    final fmt = DateFormat('MMM d, y');
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Run Payroll'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _generate,
            child: const Text('Generate',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: _loadingEmployees
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Row(children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 18),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_error!,
                            style: TextStyle(color: Colors.red[700], fontSize: 13))),
                      ]),
                    ),

                  // Period selection
                  _sectionTitle('📅 Pay Period'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(true),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Start Date',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(fmt.format(_periodStart),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                            ]),
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.grey[400]),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _pickDate(false),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                              Text('End Date',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 11)),
                              const SizedBox(height: 4),
                              Text(fmt.format(_periodEnd),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                            ]),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),
                  _sectionTitle('💼 Deduction Rate'),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Tax & Deductions'),
                            Text('${(_deductionRate * 100).toStringAsFixed(0)}%',
                                style: TextStyle(
                                    color: Colors.orange[700],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                          ],
                        ),
                        Slider(
                          value: _deductionRate,
                          min: 0,
                          max: 0.40,
                          divisions: 40,
                          activeColor: Colors.orange[700],
                          onChanged: (v) => setState(() => _deductionRate = v),
                        ),
                        Text(
                          'Applied to gross pay to calculate net pay',
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _sectionTitle('👥 Select Employees'),
                      TextButton(
                        onPressed: () => setState(() {
                          if (_selectAll) {
                            _selectedIds.clear();
                          } else {
                            _selectedIds = _employees.map((e) => e.id).toSet();
                          }
                          _selectAll = !_selectAll;
                        }),
                        child: Text(_selectAll ? 'Deselect All' : 'Select All',
                            style: TextStyle(color: Colors.orange[700])),
                      ),
                    ],
                  ),

                  if (_employees.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Center(
                        child: Text('No active employees found',
                            style: TextStyle(color: Colors.orange[700])),
                      ),
                    )
                  else
                    ...(_employees.map((e) {
                      final selected = _selectedIds.contains(e.id);
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: selected ? 2 : 0,
                        color: selected ? Colors.white : Colors.grey[100],
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => setState(() {
                            if (selected) _selectedIds.remove(e.id);
                            else _selectedIds.add(e.id);
                          }),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Checkbox(
                                value: selected,
                                activeColor: Colors.orange[700],
                                onChanged: (_) => setState(() {
                                  if (selected) _selectedIds.remove(e.id);
                                  else _selectedIds.add(e.id);
                                }),
                              ),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                    color: Colors.orange[100], shape: BoxShape.circle),
                                child: Center(
                                  child: Text(e.initials,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[700],
                                          fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(e.fullName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold, fontSize: 14)),
                                  Text(e.position,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                ]),
                              ),
                              Text(e.formattedHourlyRate,
                                  style: TextStyle(
                                      color: Colors.orange[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13)),
                            ]),
                          ),
                        ),
                      );
                    })),

                  const SizedBox(height: 24),

                  // Summary preview
                  if (_selectedIds.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.orange[200]!),
                      ),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Payroll Preview',
                            style: TextStyle(
                                color: Colors.orange[800],
                                fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Period: ${fmt.format(_periodStart)} – ${fmt.format(_periodEnd)}',
                            style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                        Text('Employees: ${_selectedIds.length}',
                            style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                        Text('Deduction Rate: ${(_deductionRate * 100).toStringAsFixed(0)}%',
                            style: TextStyle(color: Colors.orange[700], fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('* Hours will be calculated from attendance records',
                            style: TextStyle(color: Colors.orange[600], fontSize: 11)),
                      ]),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generate,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(width: 22, height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : Text(
                              'Generate Payroll for ${_selectedIds.length} Employee(s)',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(t,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );
}
