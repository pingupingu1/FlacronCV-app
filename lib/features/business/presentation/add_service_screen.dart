import 'package:flutter/material.dart';
import '../logic/business_controller.dart';

class AddServiceScreen extends StatelessWidget {
  AddServiceScreen({super.key});

  final nameCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final durationCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Service')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Service Name'),
            ),
            TextField(
              controller: priceCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            TextField(
              controller: durationCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Duration (minutes)'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await BusinessController.addService(
                  name: nameCtrl.text,
                  price: double.parse(priceCtrl.text),
                  duration: int.parse(durationCtrl.text),
                );
                Navigator.pop(context);
              },
              child: const Text('Add Service'),
            ),
          ],
        ),
      ),
    );
  }
}
