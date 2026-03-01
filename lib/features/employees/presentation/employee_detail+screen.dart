// lib/features/employees/presentation/employee_detail_screen.dart
import 'package:flutter/material.dart';

import '../../../core/models/employee_model.dart';
import '../../../core/services/employee_service.dart';

class EmployeeDetailScreen extends StatefulWidget {
  final EmployeeModel initialEmployee;
  final String businessId;

  const EmployeeDetailScreen({
    super.key,
    required this.initialEmployee,
    required this.businessId,
  });

  @override
  State<EmployeeDetailScreen> createState() => _EmployeeDetailScreenState();
}

class _EmployeeDetailScreenState extends State<EmployeeDetailScreen> {
  final _employeeService = EmployeeService();
  late String _employeeId;

  @override
  void initState() {
    super.initState();
    _employeeId = widget.initialEmployee.id;
  }

  Color _roleColor(EmployeeRole role) {
    return switch (role) {
      EmployeeRole.admin   => Colors.purple,
      EmployeeRole.manager => Colors.blue,
      EmployeeRole.staff   => Colors.green,
    };
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _infoCard(String title, List<Widget> children) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.orange[600]),
          const SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<EmployeeModel?>(
      stream: _employeeService.employeeStream(widget.businessId, _employeeId),
      initialData: widget.initialEmployee,
      builder: (context, snapshot) {
        // Loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Error
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text(
                'Error loading employee:\n${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          );
        }

        // No data
        final employee = snapshot.data;
        if (employee == null) {
          return const Scaffold(
            body: Center(child: Text('Employee not found')),
          );
        }

        // Success → show UI
        final roleColor = _roleColor(employee.role);

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Text(employee.fullName),
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteEmployee(employee),
                tooltip: 'Delete Employee',
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with avatar & gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [roleColor, roleColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        backgroundImage: employee.photoUrl != null
                            ? NetworkImage(employee.photoUrl!)
                            : null,
                        child: employee.photoUrl == null
                            ? Icon(Icons.person, size: 50, color: roleColor)
                            : null,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        employee.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        employee.position,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _badge(employee.roleLabel, Colors.white),
                          const SizedBox(width: 8),
                          _badge(employee.employmentTypeLabel, Colors.white70),
                        ],
                      ),
                      if (!employee.isActive)
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'INACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Contact info
                _infoCard(
                  'Contact Information',
                  [
                    _infoRow(Icons.email_outlined, 'Email', employee.email),
                    _infoRow(Icons.phone_outlined, 'Phone', employee.phone),
                  ],
                ),
                const SizedBox(height: 16),

                // Employment details
                _infoCard(
                  'Employment Details',
                  [
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Hire Date',
                      employee.formattedHireDate,
                    ),
                    _infoRow(
                      Icons.attach_money,
                      'Hourly Rate',
                      employee.formattedHourlyRate,
                    ),
                    if (employee.terminationDate != null)
                      _infoRow(
                        Icons.event_busy_outlined,
                        'Termination Date',
                        _formatDate(employee.terminationDate!),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Notes
                if (employee.notes != null && employee.notes!.trim().isNotEmpty)
                  _infoCard(
                    'Notes',
                    [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          employee.notes!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),

                // Actions
                const Text(
                  'Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: () => _toggleStatus(employee),
                    icon: Icon(
                      employee.isActive ? Icons.block : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      employee.isActive ? 'Deactivate Employee' : 'Reactivate Employee',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: employee.isActive ? Colors.orange : Colors.green,
                      side: BorderSide(
                        color: employee.isActive ? Colors.orange : Colors.green,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _toggleStatus(EmployeeModel employee) async {
    final willDeactivate = employee.isActive;
    final message = willDeactivate ? 'deactivated' : 'reactivated';
    final color = willDeactivate ? Colors.orange : Colors.green;

    try {
      if (willDeactivate) {
        await _employeeService.deactivateEmployee(widget.businessId, employee.id);
      } else {
        await _employeeService.reactivateEmployee(widget.businessId, employee.id);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Employee $message successfully'),
          backgroundColor: color,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteEmployee(EmployeeModel employee) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Employee?'),
        content: const Text(
          'This will permanently delete this employee record. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _employeeService.deleteEmployee(widget.businessId, employee.id);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Employee deleted successfully'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}