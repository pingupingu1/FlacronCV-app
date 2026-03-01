// lib/features/employees/presentation/employee_list_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/employee_model.dart';
import '../../../core/services/employee_service.dart';
import 'add_employee_screen.dart';
import 'employee_detail_screen.dart';

class EmployeeListScreen extends StatefulWidget {
  final String businessId;
  const EmployeeListScreen({super.key, required this.businessId});

  @override
  State<EmployeeListScreen> createState() => _EmployeeListScreenState();
}

class _EmployeeListScreenState extends State<EmployeeListScreen>
    with SingleTickerProviderStateMixin {
  final _employeeService = EmployeeService();
  late TabController _tabController;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final s = await _employeeService.getEmployeeStats(widget.businessId);
    if (mounted) setState(() => _stats = s);
  }

  Color _roleColor(EmployeeRole r) {
    switch (r) {
      case EmployeeRole.admin:   return Colors.purple;
      case EmployeeRole.manager: return Colors.blue;
      case EmployeeRole.staff:   return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Employees'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh), onPressed: _loadStats),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(text: 'Team', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'Overview', icon: Icon(Icons.bar_chart, size: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AddEmployeeScreen(businessId: widget.businessId),
          ),
        ).then((_) => _loadStats()),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Add Employee',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTeamTab(),
          _buildOverviewTab(),
        ],
      ),
    );
  }

  // ─── Team Tab ────────────────────────────────────────────────
  Widget _buildTeamTab() {
    return Column(
      children: [
        // Search bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search by name, position...',
              prefixIcon:
                  Icon(Icons.search, color: Colors.grey[400], size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _searchQuery = '');
                      },
                      child: const Icon(Icons.close, size: 18))
                  : null,
              filled: true,
              fillColor: Colors.grey[100],
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          ),
        ),

        // Employee list
        Expanded(
          child: StreamBuilder<List<EmployeeModel>>(
            stream:
                _employeeService.streamEmployees(widget.businessId),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              var employees = snap.data ?? [];

              // Filter by search
              if (_searchQuery.isNotEmpty) {
                employees = employees
                    .where((e) =>
                        e.fullName
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        e.position
                            .toLowerCase()
                            .contains(_searchQuery) ||
                        e.email.toLowerCase().contains(_searchQuery))
                    .toList();
              }

              if (employees.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline,
                          size: 72, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                          _searchQuery.isNotEmpty
                              ? 'No employees match "$_searchQuery"'
                              : 'No employees yet',
                          style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      if (_searchQuery.isEmpty)
                        Text('Add your first team member',
                            style:
                                TextStyle(color: Colors.grey[500])),
                    ],
                  ),
                );
              }

              // Group active vs inactive
              final active =
                  employees.where((e) => e.isActive).toList();
              final inactive =
                  employees.where((e) => !e.isActive).toList();

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  if (active.isNotEmpty) ...[
                    _sectionHeader(
                        'Active', active.length, Colors.green),
                    ...active.map((e) => _employeeCard(e)),
                    const SizedBox(height: 8),
                  ],
                  if (inactive.isNotEmpty) ...[
                    _sectionHeader(
                        'Inactive', inactive.length, Colors.grey),
                    ...inactive.map((e) => _employeeCard(e)),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(width: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10)),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ),
      ]),
    );
  }

  Widget _employeeCard(EmployeeModel employee) {
    final roleColor = _roleColor(employee.role);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EmployeeDetailScreen(
              employee: employee,
              businessId: widget.businessId,
            ),
          ),
        ).then((_) => _loadStats()),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: employee.isActive
                    ? roleColor.withValues(alpha: 0.15)
                    : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  employee.initials,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: employee.isActive
                          ? roleColor
                          : Colors.grey[500]),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(employee.fullName,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: employee.isActive
                                ? Colors.black87
                                : Colors.grey)),
                    if (!employee.isActive) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius:
                                BorderRadius.circular(6)),
                        child: const Text('Inactive',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey)),
                      ),
                    ],
                  ]),
                  const SizedBox(height: 3),
                  Text(employee.position,
                      style: TextStyle(
                          color: Colors.grey[600], fontSize: 13)),
                  const SizedBox(height: 3),
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: roleColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6)),
                      child: Text(employee.roleLabel,
                          style: TextStyle(
                              color: roleColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text('• ${employee.employmentLabel}',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 11)),
                  ]),
                ],
              ),
            ),
            // Rate
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(employee.formattedHourlyRate,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Colors.orange[700])),
                const SizedBox(height: 4),
                Icon(Icons.chevron_right,
                    color: Colors.grey[400], size: 18),
              ],
            ),
          ]),
        ),
      ),
    );
  }

  // ─── Overview Tab ────────────────────────────────────────────
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat cards
          Row(children: [
            Expanded(
                child: _statCard('Total', _stats['total'] ?? 0,
                    Icons.people, Colors.orange)),
            const SizedBox(width: 10),
            Expanded(
                child: _statCard('Active', _stats['active'] ?? 0,
                    Icons.check_circle_outline, Colors.green)),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _statCard('Full Time', _stats['fullTime'] ?? 0,
                    Icons.work_outline, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(
                child: _statCard('Part Time', _stats['partTime'] ?? 0,
                    Icons.work_history_outlined, Colors.purple)),
          ]),
          const SizedBox(height: 24),

          // Role breakdown
          const Text('Team by Role',
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 12),
          StreamBuilder<List<EmployeeModel>>(
            stream: _employeeService
                .streamActiveEmployees(widget.businessId),
            builder: (_, snap) {
              final employees = snap.data ?? [];
              final roles = {
                EmployeeRole.admin:
                    employees.where((e) => e.role == EmployeeRole.admin).length,
                EmployeeRole.manager:
                    employees.where((e) => e.role == EmployeeRole.manager).length,
                EmployeeRole.staff:
                    employees.where((e) => e.role == EmployeeRole.staff).length,
              };
              final types = {
                EmploymentType.fullTime:
                    employees.where((e) => e.employmentType == EmploymentType.fullTime).length,
                EmploymentType.partTime:
                    employees.where((e) => e.employmentType == EmploymentType.partTime).length,
                EmploymentType.contract:
                    employees.where((e) => e.employmentType == EmploymentType.contract).length,
                EmploymentType.intern:
                    employees.where((e) => e.employmentType == EmploymentType.intern).length,
              };
              final totalPay = employees.fold(
                  0.0, (sum, e) => sum + e.hourlyRate);

              return Column(children: [
                Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _breakdownRow('Admin', roles[EmployeeRole.admin] ?? 0, Colors.purple),
                      _breakdownRow('Manager', roles[EmployeeRole.manager] ?? 0, Colors.blue),
                      _breakdownRow('Staff', roles[EmployeeRole.staff] ?? 0, Colors.teal),
                      const Divider(),
                      _breakdownRow('Full Time', types[EmploymentType.fullTime] ?? 0, Colors.blue),
                      _breakdownRow('Part Time', types[EmploymentType.partTime] ?? 0, Colors.purple),
                      _breakdownRow('Contract', types[EmploymentType.contract] ?? 0, Colors.orange),
                      _breakdownRow('Intern', types[EmploymentType.intern] ?? 0, Colors.teal),
                      const Divider(),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Est. Hourly Payroll',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text('\$${totalPay.toStringAsFixed(2)}/hr',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                                fontSize: 15)),
                      ]),
                    ]),
                  ),
                ),
              ]);
            },
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _statCard(String label, int value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$value',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: color)),
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        ]),
      ]),
    );
  }

  Widget _breakdownRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(width: 10, height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 13)),
        ]),
        Text('$count',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
      ]),
    );
  }
}
