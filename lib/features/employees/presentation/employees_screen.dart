import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'employee_detail_screen.dart'; // Make sure this exists

class EmployeesScreen extends StatefulWidget {
  final String businessId;

  const EmployeesScreen({
    super.key,
    required this.businessId,
  });

  @override
  State<EmployeesScreen> createState() => _EmployeesScreenState();
}

class _EmployeesScreenState extends State<EmployeesScreen> {
  bool _isGridView = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Employees'),
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () => setState(() => _isGridView = !_isGridView),
            tooltip: _isGridView ? 'Switch to List' : 'Switch to Grid',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _navigateToDetail(isNew: true),
            tooltip: 'Add Employee',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('businesses/${widget.businessId}/employees')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Error loading employees:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No employees yet',
                    style: TextStyle(fontSize: 20, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text('Tap + to add your first employee'),
                ],
              ),
            );
          }

          if (_isGridView) {
            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: docs.length,
              itemBuilder: (context, index) => _buildEmployeeCard(docs[index]),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) => _buildEmployeeListTile(docs[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmployeeListTile(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] as String? ?? 'Unnamed';
    final role = data['role'] as String? ?? 'No role';
    final hourlyRate = (data['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final active = data['activeStatus'] != false; // default true

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: active ? Colors.green[100] : Colors.red[100],
        foregroundColor: active ? Colors.green[800] : Colors.red[800],
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      ),
      title: Text(name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(role, style: const TextStyle(fontSize: 13)),
          Text(
            '\$${hourlyRate.toStringAsFixed(2)} /hr • ${active ? 'Active' : 'Inactive'}',
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.green[700] : Colors.red[700],
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToDetail(employeeId: doc.id),
    );
  }

  Widget _buildEmployeeCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final name = data['name'] as String? ?? 'Unnamed';
    final role = data['role'] as String? ?? '—';
    final hourlyRate = (data['hourlyRate'] as num?)?.toDouble() ?? 0.0;
    final active = data['activeStatus'] != false;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToDetail(employeeId: doc.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: active ? Colors.green[100] : Colors.red[100],
                foregroundColor: active ? Colors.green[800] : Colors.red[800],
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                role,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                '\$${hourlyRate.toStringAsFixed(2)} /hr',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Chip(
                label: Text(
                  active ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 12,
                    color: active ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                backgroundColor: active ? Colors.green[50] : Colors.red[50],
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToDetail({String? employeeId, bool isNew = false}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EmployeeDetailScreen(
          businessId: widget.businessId,
          employeeId: employeeId,
          ),
      ),
    );
  }
}