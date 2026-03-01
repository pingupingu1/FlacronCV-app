// lib/features/business/presentation/business_profile_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/business_model.dart';
import '../../../core/services/business_service.dart';
import '../../../routes/route_names.dart';

class BusinessProfileScreen extends StatefulWidget {
  final String businessId;
  const BusinessProfileScreen({super.key, required this.businessId});

  @override
  State<BusinessProfileScreen> createState() => _BusinessProfileScreenState();
}

class _BusinessProfileScreenState extends State<BusinessProfileScreen> {
  final _businessService = BusinessService();
  final _formKey = GlobalKey<FormState>();

  BusinessModel? _business;
  bool _isLoading = true;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _categoryCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _stateCtrl;
  late TextEditingController _websiteCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _categoryCtrl = TextEditingController();
    _descCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _cityCtrl = TextEditingController();
    _stateCtrl = TextEditingController();
    _websiteCtrl = TextEditingController();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _categoryCtrl.dispose(); _descCtrl.dispose();
    _phoneCtrl.dispose(); _emailCtrl.dispose(); _addressCtrl.dispose();
    _cityCtrl.dispose(); _stateCtrl.dispose(); _websiteCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final business = await _businessService.getBusiness(widget.businessId);
    if (business != null && mounted) {
      setState(() {
        _business = business;
        _nameCtrl.text = business.name;
        _categoryCtrl.text = business.category;
        _descCtrl.text = business.description ?? '';
        _phoneCtrl.text = business.phone ?? '';
        _emailCtrl.text = business.email ?? '';
        _addressCtrl.text = business.address ?? '';
        _cityCtrl.text = business.city ?? '';
        _stateCtrl.text = business.state ?? '';
        _websiteCtrl.text = business.website ?? '';
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _businessService.updateBusiness(widget.businessId, {
        'name': _nameCtrl.text.trim(),
        'category': _categoryCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'state': _stateCtrl.text.trim(),
        'website': _websiteCtrl.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Profile saved successfully!'),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Business Profile'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Text('Save',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo placeholder
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 90,
                            height: 90,
                            decoration: BoxDecoration(
                              color: Colors.orange[100],
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.orange[300]!, width: 2),
                            ),
                            child: Icon(Icons.store,
                                color: Colors.orange[700], size: 40),
                          ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {},
                            icon: Icon(Icons.camera_alt_outlined,
                                size: 16, color: Colors.orange[700]),
                            label: Text('Change Logo',
                                style: TextStyle(color: Colors.orange[700])),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    _sectionHeader('Business Info'),
                    _field(_nameCtrl, 'Business Name *', Icons.store_outlined,
                        required: true),
                    _field(_categoryCtrl, 'Category', Icons.category_outlined),
                    _multilineField(_descCtrl, 'Description'),

                    const SizedBox(height: 8),
                    _sectionHeader('Contact'),
                    _field(_phoneCtrl, 'Phone', Icons.phone_outlined,
                        type: TextInputType.phone),
                    _field(_emailCtrl, 'Email', Icons.email_outlined,
                        type: TextInputType.emailAddress),
                    _field(_websiteCtrl, 'Website', Icons.language_outlined,
                        type: TextInputType.url),

                    const SizedBox(height: 8),
                    _sectionHeader('Location'),
                    _field(_addressCtrl, 'Street Address',
                        Icons.location_on_outlined),
                    Row(children: [
                      Expanded(
                          flex: 2,
                          child: _field(_cityCtrl, 'City',
                              Icons.location_city_outlined)),
                      const SizedBox(width: 10),
                      Expanded(child: _field(_stateCtrl, 'State', null)),
                    ]),

                    const SizedBox(height: 8),
                    _sectionHeader('Quick Actions'),
                    _actionTile(
                      Icons.access_time,
                      'Business Hours',
                      'Set your opening times',
                      () => Navigator.pushNamed(context, RouteNames.businessHours,
                          arguments: {'businessId': widget.businessId}),
                    ),
                    _actionTile(
                      Icons.content_cut,
                      'Services',
                      'Manage your service offerings',
                      () => Navigator.pushNamed(context, RouteNames.services,
                          arguments: {'businessId': widget.businessId}),
                    ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _save,
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save Profile',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(title,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.orange[700],
              letterSpacing: 0.5)),
    );
  }

  Widget _field(
      TextEditingController ctrl, String label, IconData? icon,
      {TextInputType type = TextInputType.text, bool required = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey[400], size: 20)
              : null,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
        validator: required
            ? (v) =>
                (v == null || v.trim().isEmpty) ? '$label is required' : null
            : null,
      ),
    );
  }

  Widget _multilineField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: label,
          alignLabelWithHint: true,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey[300]!)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.orange[700]!, width: 2)),
        ),
      ),
    );
  }

  Widget _actionTile(
      IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.orange[700], size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: Text(subtitle,
            style: TextStyle(color: Colors.grey[600], fontSize: 12)),
        trailing:
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
        onTap: onTap,
      ),
    );
  }
}
