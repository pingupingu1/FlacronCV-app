// lib/features/business/presentation/services_screen.dart

import 'package:flutter/material.dart';
import '../../../core/models/service_model.dart';
import '../../../core/services/business_service.dart';

class ServicesScreen extends StatefulWidget {
  final String businessId;
  const ServicesScreen({super.key, required this.businessId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _businessService = BusinessService();

  void _showServiceDialog({ServiceModel? service}) {
    final nameCtrl = TextEditingController(text: service?.name ?? '');
    final priceCtrl = TextEditingController(
        text: service != null ? service.price.toStringAsFixed(2) : '');
    final descCtrl = TextEditingController(text: service?.description ?? '');
    int duration = service?.durationMinutes ?? 60;
    bool isLoading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(service == null ? 'Add Service' : 'Edit Service',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 16),
                _modalLabel('Service Name *'),
                const SizedBox(height: 6),
                _modalTextField(nameCtrl, 'e.g. Haircut & Style'),
                const SizedBox(height: 14),
                _modalLabel('Price (\$) *'),
                const SizedBox(height: 6),
                _modalTextField(priceCtrl, '0.00',
                    type: TextInputType.number),
                const SizedBox(height: 14),
                _modalLabel('Duration'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [30, 45, 60, 90, 120].map((min) {
                    final sel = duration == min;
                    return GestureDetector(
                      onTap: () => setModal(() => duration = min),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? Colors.orange[700] : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: sel
                                  ? Colors.orange[700]!
                                  : Colors.grey[300]!),
                        ),
                        child: Text(
                          min < 60 ? '${min}min' : '${min ~/ 60}h${min % 60 > 0 ? ' ${min % 60}m' : ''}',
                          style: TextStyle(
                              color: sel ? Colors.white : Colors.grey[700],
                              fontWeight: FontWeight.w600,
                              fontSize: 12),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                _modalLabel('Description (optional)'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: InputDecoration(
                    hintText: 'Describe this service...',
                    filled: true,
                    fillColor: Colors.grey[50],
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            if (nameCtrl.text.trim().isEmpty) return;
                            setModal(() => isLoading = true);
                            try {
                              if (service == null) {
                                await _businessService.addService(
                                  businessId: widget.businessId,
                                  name: nameCtrl.text.trim(),
                                  price: double.tryParse(priceCtrl.text) ?? 0,
                                  durationMinutes: duration,
                                  description: descCtrl.text.trim().isEmpty
                                      ? null
                                      : descCtrl.text.trim(),
                                );
                              } else {
                                await _businessService.updateService(
                                  widget.businessId,
                                  service.id,
                                  {
                                    'name': nameCtrl.text.trim(),
                                    'price': double.tryParse(priceCtrl.text) ?? 0,
                                    'durationMinutes': duration,
                                    'description': descCtrl.text.trim().isEmpty
                                        ? null
                                        : descCtrl.text.trim(),
                                  },
                                );
                              }
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              setModal(() => isLoading = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2.5))
                        : Text(service == null ? 'Add Service' : 'Save Changes',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteService(ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Service'),
        content: Text('Delete "${service.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _businessService.deleteService(widget.businessId, service.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Services'),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showServiceDialog(),
        backgroundColor: Colors.orange[700],
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Service',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: StreamBuilder<List<ServiceModel>>(
        stream: _businessService.streamServices(widget.businessId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final services = snapshot.data ?? [];

          if (services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.content_cut_outlined,
                      size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text('No services yet',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[600])),
                  const SizedBox(height: 8),
                  Text('Add your first service to get started',
                      style: TextStyle(color: Colors.grey[500])),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showServiceDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 2,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.content_cut,
                        color: Colors.orange[700], size: 22),
                  ),
                  title: Text(service.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Row(children: [
                        Icon(Icons.access_time,
                            size: 14, color: Colors.grey[500]),
                        const SizedBox(width: 4),
                        Text(service.formattedDuration,
                            style: TextStyle(
                                color: Colors.grey[600], fontSize: 13)),
                      ]),
                      if (service.description != null &&
                          service.description!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(service.description!,
                            style: TextStyle(
                                color: Colors.grey[500], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(service.formattedPrice,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700])),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (val) {
                          if (val == 'edit')
                            _showServiceDialog(service: service);
                          if (val == 'delete') _deleteService(service);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'edit',
                              child: Row(children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Edit'),
                              ])),
                          const PopupMenuItem(
                              value: 'delete',
                              child: Row(children: [
                                Icon(Icons.delete_outline,
                                    size: 18, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Delete',
                                    style: TextStyle(color: Colors.red)),
                              ])),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _modalLabel(String text) {
    return Text(text,
        style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1A1A1A)));
  }

  Widget _modalTextField(TextEditingController ctrl, String hint,
      {TextInputType type = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.grey[50],
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
