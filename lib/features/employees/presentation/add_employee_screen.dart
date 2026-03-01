// lib/features/employees/presentation/add_employee_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/employee_service.dart';

class AddEmployeeScreen extends StatefulWidget {
  final String businessId;
  final EmployeeModel? employee; // if provided, edit mode

  const AddEmployeeScreen({
    super.key,
    required this.businessId,
    this.employee,
  });

  @override
  State<AddEmployeeScreen> createState() => _AddEmployeeScreenState();
}

class _AddEmployeeScreenState extends State<AddEmployeeScreen> {
  final _employeeService = EmployeeService();
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _positionCtrl = TextEditingController();
  final _rateCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  EmployeeRole _role = EmployeeRole.staff;
  EmploymentType _employmentType = EmploymentType.fullTime;
  DateTime _hireDate = DateTime.now();
  bool _isLoading = false;
  String? _error;

  bool get _isEdit => widget.employee != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      final e = widget.employee!;
      _nameCtrl.text = e.fullName;
      _emailCtrl.text = e.email;
      _phoneCtrl.text = e.phone;
      _positionCtrl.text = e.position;
      _rateCtrl.text = e.hourlyRate.toStringAsFixed(2);
      _notesCtrl.text = e.notes ?? '';
      _role = e.role;
      _employmentType = e.employmentType;
      _hireDate = e.hireDate;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _positionCtrl.dispose();
    _rateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickHireDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _hireDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.orange[700]!),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _hireDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });

    try {
      if (_isEdit) {
        await _employeeService.updateEmployee(
          widget.businessId,
          widget.employee!.id,
          {
            'fullName': _nameCtrl.text.trim(),
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'position': _positionCtrl.text.trim(),
            'hourlyRate': double.tryParse(_rateCtrl.text) ?? 0,
            'role': _role.name,
            'employmentType': _employmentType.name,
            'hireDate': _hireDate.toIso8601String(),
            'notes': _notesCtrl.text.trim(),
          },
        );
      } else {
        await _employeeService.createEmployee(
          businessId: widget.businessId,
          fullName: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          position: _positionCtrl.text.trim(),
          role: _role,
          employmentType: _employmentType,
          hourlyRate: double.tryParse(_rateCtrl.text) ?? 0,
          hireDate: _hireDate,
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        );
      }
      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Employee updated successfully ✓'
                : 'Employee added successfully ✓'),
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
        title: Text(_isEdit ? 'Edit Employee' : 'Add Employee'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: Text(_isEdit ? 'Save' : 'Add',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar preview
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      _nameCtrl.text.isNotEmpty
                          ? _nameCtrl.text.trim().split(' ').map((p) => p[0]).take(2).join().toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700]),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

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
                    Expanded(child: Text(_error!, style: TextStyle(color: Colors.red[700], fontSize: 13))),
                  ]),
                ),

              _sectionTitle('Personal Info'),
              _field(_nameCtrl, 'Full Name *', Icons.person_outline, required: true,
                  onChanged: (_) => setState(() {})),
              _field(_emailCtrl, 'Email *', Icons.email_outlined,
                  required: true, type: TextInputType.emailAddress),
              _field(_phoneCtrl, 'Phone *', Icons.phone_outlined,
                  required: true, type: TextInputType.phone),

              _sectionTitle('Employment'),
              _field(_positionCtrl, 'Job Title / Position *',
                  Icons.work_outline, required: true),
              _field(_rateCtrl, 'Hourly Rate (\$) *', Icons.attach_money,
                  required: true,
                  type: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if (double.tryParse(v) == null) return 'Invalid number';
                    return null;
                  }),

              // Role selector
              const SizedBox(height: 4),
              _label('Role *'),
              const SizedBox(height: 8),
              Row(children: EmployeeRole.values.map((r) {
                final selected = _role == r;
                final color = r == EmployeeRole.admin
                    ? Colors.purple
                    : r == EmployeeRole.manager
                        ? Colors.blue
                        : Colors.teal;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _role = r),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: selected ? color.withValues(alpha: 0.1) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: selected ? color : Colors.grey[300]!,
                            width: selected ? 2 : 1),
                      ),
                      child: Column(children: [
                        Icon(
                          r == EmployeeRole.admin
                              ? Icons.admin_panel_settings_outlined
                              : r == EmployeeRole.manager
                                  ? Icons.manage_accounts_outlined
                                  : Icons.person_outline,
                          color: selected ? color : Colors.grey[400],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          r == EmployeeRole.admin ? 'Admin' : r == EmployeeRole.manager ? 'Manager' : 'Staff',
                          style: TextStyle(
                              fontSize: 11,
                              color: selected ? color : Colors.grey[600],
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal),
                        ),
                      ]),
                    ),
                  ),
                );
              }).toList()),

              const SizedBox(height: 16),
              _label('Employment Type *'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: EmploymentType.values.map((t) {
                  final selected = _employmentType == t;
                  final label = t == EmploymentType.fullTime
                      ? 'Full Time'
                      : t == EmploymentType.partTime
                          ? 'Part Time'
                          : t == EmploymentType.contract
                              ? 'Contract'
                              : 'Intern';
                  return GestureDetector(
                    onTap: () => setState(() => _employmentType = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected ? Colors.orange[700] : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: selected ? Colors.orange[700]! : Colors.grey[300]!),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              color: selected ? Colors.white : Colors.grey[700],
                              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),
              _label('Hire Date *'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickHireDate,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Row(children: [
                    Icon(Icons.calendar_today, color: Colors.grey[400], size: 20),
                    const SizedBox(width: 12),
                    Text(DateFormat('MMMM d, y').format(_hireDate),
                        style: const TextStyle(fontSize: 14)),
                  ]),
                ),
              ),

              const SizedBox(height: 16),
              _sectionTitle('Notes'),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Any additional notes about this employee...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey[300]!)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
                ),
              ),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(_isEdit ? 'Save Changes' : 'Add Employee',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 8),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)));

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text,
      bool required = false,
      String? Function(String?)? validator,
      void Function(String)? onChanged}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
        validator: validator ?? (required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null),
      ),
    );
  }
}
