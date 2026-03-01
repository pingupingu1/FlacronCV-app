// lib/features/business/presentation/business_setup_screen.dart

import 'package:flutter/material.dart';
import '../../../core/services/business_service.dart';
import '../../../routes/route_names.dart';

class BusinessSetupScreen extends StatefulWidget {
  const BusinessSetupScreen({super.key});

  @override
  State<BusinessSetupScreen> createState() => _BusinessSetupScreenState();
}

class _BusinessSetupScreenState extends State<BusinessSetupScreen> {
  final _businessService = BusinessService();
  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Business Info
  final _nameController = TextEditingController();
  final _categoryController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'Beauty & Wellness';

  // Step 2: Contact & Location
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _websiteController = TextEditingController();

  // Step 3: First Service
  final _serviceNameController = TextEditingController();
  final _servicePriceController = TextEditingController();
  final _serviceDescController = TextEditingController();
  int _serviceDuration = 60;

  final List<String> _categories = [
    'Beauty & Wellness',
    'Health & Fitness',
    'Medical & Dental',
    'Legal & Consulting',
    'Education & Tutoring',
    'Home Services',
    'Auto Services',
    'Restaurant & Food',
    'Photography',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _websiteController.dispose();
    _serviceNameController.dispose();
    _servicePriceController.dispose();
    _serviceDescController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      setState(() => _currentStep++);
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _complete();
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _complete() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Business name is required');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final businessId = await _businessService.createBusiness(
        name: _nameController.text.trim(),
        category: _selectedCategory,
        description: _descriptionController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        address: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        website: _websiteController.text.trim(),
      );

      // Add first service if provided
      if (_serviceNameController.text.trim().isNotEmpty) {
        await _businessService.addService(
          businessId: businessId,
          name: _serviceNameController.text.trim(),
          price: double.tryParse(_servicePriceController.text) ?? 0,
          durationMinutes: _serviceDuration,
          description: _serviceDescController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, RouteNames.dashboard);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange[700]!, Colors.orange[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.business_center,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 10),
                    const Text('FlacronControl',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 24),
                const Text("Let's set up your business",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text('Step ${_currentStep + 1} of 3',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 14)),
                const SizedBox(height: 16),
                // Progress bar
                Row(
                  children: List.generate(3, (i) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentStep
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),

          // Steps
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildStep1(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
          ),

          // Error
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              color: Colors.red[50],
              child: Row(children: [
                Icon(Icons.error_outline, color: Colors.red[700], size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style:
                          TextStyle(color: Colors.red[700], fontSize: 13)),
                ),
              ]),
            ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4))
              ],
            ),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _prevStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[300]!),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Back',
                          style: TextStyle(
                              color: Colors.grey, fontWeight: FontWeight.w600)),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(
                            _currentStep == 2 ? 'Launch My Business! 🚀' : 'Continue',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📋', 'Business Information',
              'Tell us about your business'),
          const SizedBox(height: 24),
          _label('Business Name *'),
          const SizedBox(height: 6),
          _textField(_nameController, 'e.g. Smith & Co Beauty Salon',
              Icons.store_outlined),
          const SizedBox(height: 16),
          _label('Business Category *'),
          const SizedBox(height: 6),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                borderRadius: BorderRadius.circular(10),
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) =>
                    setState(() => _selectedCategory = v ?? _selectedCategory),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText:
                  'Describe what your business does, your specialties...',
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
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('📍', 'Contact & Location',
              'How can customers find and reach you?'),
          const SizedBox(height: 24),
          _label('Phone Number'),
          const SizedBox(height: 6),
          _textField(_phoneController, '+1 (555) 000-0000', Icons.phone_outlined,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _label('Business Email'),
          const SizedBox(height: 6),
          _textField(_emailController, 'hello@yourbusiness.com',
              Icons.email_outlined,
              type: TextInputType.emailAddress),
          const SizedBox(height: 16),
          _label('Street Address'),
          const SizedBox(height: 6),
          _textField(
              _addressController, '123 Main Street', Icons.location_on_outlined),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('City'),
                    const SizedBox(height: 6),
                    _textField(_cityController, 'New York', Icons.location_city_outlined),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('State'),
                    const SizedBox(height: 6),
                    _textField(_stateController, 'NY', null),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Website (optional)'),
          const SizedBox(height: 6),
          _textField(
              _websiteController, 'www.yourbusiness.com', Icons.language_outlined,
              type: TextInputType.url),
        ],
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('✂️', 'Your First Service',
              'Add one service to get started — you can add more later'),
          const SizedBox(height: 24),
          _label('Service Name'),
          const SizedBox(height: 6),
          _textField(_serviceNameController, 'e.g. Haircut & Style',
              Icons.content_cut_outlined),
          const SizedBox(height: 16),
          _label('Price (\$)'),
          const SizedBox(height: 6),
          _textField(_servicePriceController, '50.00', Icons.attach_money,
              type: TextInputType.number),
          const SizedBox(height: 16),
          _label('Duration'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [30, 45, 60, 90, 120].map((min) {
              final selected = _serviceDuration == min;
              return GestureDetector(
                onTap: () => setState(() => _serviceDuration = min),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? Colors.orange[700] : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: selected
                            ? Colors.orange[700]!
                            : Colors.grey[300]!),
                  ),
                  child: Text(
                    min < 60
                        ? '${min}min'
                        : min == 60
                            ? '1 hour'
                            : '${min ~/ 60}h ${min % 60 > 0 ? '${min % 60}min' : ''}',
                    style: TextStyle(
                        color: selected ? Colors.white : Colors.grey[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          _label('Description (optional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: _serviceDescController,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'Briefly describe this service...',
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
                  borderSide:
                      BorderSide(color: Colors.orange[700]!, width: 2)),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(children: [
              Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You can skip this step and add services later from your dashboard.',
                  style: TextStyle(
                      color: Colors.orange[800],
                      fontSize: 13,
                      height: 1.4),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String emoji, String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A))),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A)));
  }

  Widget _textField(
      TextEditingController controller, String hint, IconData? icon,
      {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon:
            icon != null ? Icon(icon, color: Colors.grey[400], size: 20) : null,
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
    );
  }
}
