// lib/features/employees/presentation/employee_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/employee_service.dart';
import 'add_employee_screen.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final dynamic employee;
  final String? businessId;
  final String? employeeId;

  const EmployeeDetailScreen({
    super.key,
    this.employee,
    this.businessId,
    this.employeeId,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _employeeService = EmployeeService();
  EmployeeModel? _employee;
  bool _isLoading = true;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    if (widget.employee is EmployeeModel) {
      _employee = widget.employee as EmployeeModel;
      _isLoading = false;
    } else {
      _loadEmployee();
    }
  }

  Future<void> _loadEmployee() async {
    if (widget.businessId == null || widget.employeeId == null) {
      setState(() => _isLoading = false);
      return;
    }
    final e = await _employeeService.getEmployee(
        widget.businessId!, widget.employeeId!);
    if (mounted) setState(() { _employee = e; _isLoading = false; });
  }

  String get _businessId => _employee?.businessId ?? widget.businessId ?? '';

  Color get _roleColor {
    switch (_employee?.role) {
      case EmployeeRole.admin:   return Colors.purple;
      case EmployeeRole.manager: return Colors.blue;
      default:                   return Colors.teal;
    }
  }

  Future<void> _toggleActive() async {
    if (_employee == null) return;
    final newStatus = !_employee!.isActive;
    final action = newStatus ? 'Reactivate' : 'Deactivate';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('$action Employee?'),
        content: Text(
            '${action} ${_employee!.fullName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: newStatus ? Colors.green : Colors.red,
                foregroundColor: Colors.white),
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _isUpdating = true);
    await _employeeService.setActiveStatus(_businessId, _employee!.id, newStatus);
    setState(() {
      _employee = _employee!.copyWith(isActive: newStatus);
      _isUpdating = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_employee!.fullName} ${newStatus ? 'reactivated' : 'deactivated'}'),
        backgroundColor: newStatus ? Colors.green : Colors.orange,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _deleteEmployee() async {
    if (_employee == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Employee?'),
        content: Text('Permanently delete ${_employee!.fullName}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await _employeeService.deleteEmployee(_businessId, _employee!.id);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (_employee == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Employee')),
        body: const Center(child: Text('Employee not found')),
      );
    }

    final e = _employee!;
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(e.fullName),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AddEmployeeScreen(
                  businessId: _businessId,
                  employee: e,
                ),
              ),
            ).then((updated) {
              if (updated == true) _loadEmployee();
            }),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteEmployee,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange[700]!, Colors.orange[500]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(e.initials,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 12),
                Text(e.fullName,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(e.position,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 15)),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  _badge(e.roleLabel, _roleColor),
                  const SizedBox(width: 8),
                  _badge(e.employmentLabel, Colors.white.withValues(alpha: 0.2),
                      textColor: Colors.white),
                  const SizedBox(width: 8),
                  _badge(
                    e.isActive ? 'Active' : 'Inactive',
                    e.isActive
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    textColor: Colors.white,
                  ),
                ]),
              ]),
            ),
            const SizedBox(height: 16),

            // Contact
            _card('Contact', [
              _row(Icons.email_outlined, 'Email', e.email),
              _row(Icons.phone_outlined, 'Phone', e.phone),
            ]),
            const SizedBox(height: 12),

            // Employment
            _card('Employment', [
              _row(Icons.attach_money, 'Hourly Rate', e.formattedHourlyRate,
                  valueColor: Colors.orange[700]),
              _row(Icons.calendar_today, 'Hire Date',
                  DateFormat('MMMM d, y').format(e.hireDate)),
              _row(Icons.work_outline, 'Type', e.employmentLabel),
              _row(Icons.admin_panel_settings_outlined, 'Role', e.roleLabel),
            ]),
            const SizedBox(height: 12),

            if (e.notes != null && e.notes!.isNotEmpty)
              _card('Notes', [
                Text(e.notes!,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        height: 1.5)),
              ]),

            const SizedBox(height: 20),

            // Actions
            if (!_isUpdating) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: _toggleActive,
                  icon: Icon(
                      e.isActive ? Icons.person_off_outlined : Icons.person_outline,
                      size: 18,
                      color: e.isActive ? Colors.red : Colors.green),
                  label: Text(
                      e.isActive ? 'Deactivate Employee' : 'Reactivate Employee',
                      style: TextStyle(
                          color: e.isActive ? Colors.red : Colors.green,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: (e.isActive ? Colors.red : Colors.green)
                            .withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else
              const Center(child: CircularProgressIndicator()),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color bgColor, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: TextStyle(
              color: textColor ?? Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _card(String title, List<Widget> rows) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange[700],
                    letterSpacing: 0.5)),
            const SizedBox(height: 12),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.orange[300]),
        const SizedBox(width: 10),
        Text('$label:',
            style: const TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.w500)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: valueColor ?? Colors.black87),
              textAlign: TextAlign.right),
        ),
      ]),
    );
  }
}
