// lib/modules/admin/ui/admin_dashboard_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../routes/route_names.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // Summary stats
  int _totalBusinesses = 0;
  int _totalUsers = 0;
  double _totalRevenue = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAdminStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminStats() async {
    setState(() => _isLoading = true);
    try {
      final businesses = await _firestore.collection('businesses').get();
      _totalBusinesses = businesses.docs.length;

      final users = await _firestore.collection('users').get();
      _totalUsers = users.docs.length;

      // Aggregate revenue across all businesses
      double revenue = 0;
      for (final biz in businesses.docs) {
        final invoices = await _firestore
            .collection('businesses')
            .doc(biz.id)
            .collection('invoices')
            .where('status', isEqualTo: 'paid')
            .get();
        for (final inv in invoices.docs) {
          revenue += (inv.data()['amount'] ?? 0).toDouble();
        }
      }
      _totalRevenue = revenue;
    } catch (e) {
      debugPrint('Admin stats error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange[900],
        foregroundColor: Colors.white,
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings, size: 22),
            SizedBox(width: 8),
            Text('Super Admin', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAdminStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, RouteNames.home);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard_outlined), text: 'Overview'),
            Tab(icon: Icon(Icons.business_outlined), text: 'Businesses'),
            Tab(icon: Icon(Icons.people_outlined), text: 'Users'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.orange))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildBusinessesTab(),
                _buildUsersTab(),
              ],
            ),
    );
  }

  // ── OVERVIEW TAB ──
  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadAdminStats,
      color: Colors.orange,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Platform Overview',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Stats row
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _adminStatCard('Total Businesses', '$_totalBusinesses',
                    Icons.business_outlined, Colors.blue),
                _adminStatCard('Total Users', '$_totalUsers',
                    Icons.people_outlined, Colors.green),
                _adminStatCard('Total Revenue',
                    '\$${_totalRevenue.toStringAsFixed(0)}',
                    Icons.attach_money, Colors.orange),
                _adminStatCard('Active Plans', '$_totalBusinesses',
                    Icons.verified_outlined, Colors.purple),
              ],
            ),
            const SizedBox(height: 24),

            // Plan distribution
            const Text('Subscription Plans',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _planCard('Starter', '\$39/mo', Colors.grey, 0),
            _planCard('Growth', '\$99/mo', Colors.blue, 0),
            _planCard('Pro', '\$249/mo', Colors.orange, 0),
            _planCard('Enterprise', '\$499/mo', Colors.purple, 0),
          ],
        ),
      ),
    );
  }

  Widget _adminStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 2),
        ],
      ),
    );
  }

  Widget _planCard(String plan, String price, Color color, int count) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(price, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text('$count clients',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  // ── BUSINESSES TAB ──
  Widget _buildBusinessesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('businesses')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No businesses registered yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.orange[100],
                  child: Icon(Icons.business, color: Colors.orange[700]),
                ),
                title: Text(data['name'] ?? 'Unnamed',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (data['category'] != null)
                      Text(data['category'],
                          style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    Text(data['phone'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: data['isActive'] == true
                        ? Colors.green[50]
                        : Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    data['isActive'] == true ? 'Active' : 'Inactive',
                    style: TextStyle(
                        color: data['isActive'] == true
                            ? Colors.green[700]
                            : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
                isThreeLine: true,
              ),
            );
          },
        );
      },
    );
  }

  // ── USERS TAB ──
  Widget _buildUsersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('users')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.orange));
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Center(child: Text('No users yet'));
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final role = data['role'] ?? 'customer';
            Color roleColor = role == 'businessOwner'
                ? Colors.blue
                : role == 'employee'
                    ? Colors.green
                    : Colors.grey;
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: roleColor.withOpacity(0.1),
                  backgroundImage: data['photoUrl'] != null
                      ? NetworkImage(data['photoUrl']) : null,
                  child: data['photoUrl'] == null
                      ? Icon(Icons.person, color: roleColor) : null,
                ),
                title: Text(data['displayName'] ?? 'Unknown',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(data['email'] ?? '',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role,
                      style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            );
          },
        );
      },
    );
  }
}