import 'package:flutter/material.dart';
import '../logic/business_controller.dart';
import '../../../routes/route_names.dart';

class CreateBusinessScreen extends StatelessWidget {
  CreateBusinessScreen({super.key});

  final nameCtrl = TextEditingController();
  final categoryCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final addressCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Business')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Business Name'),
            ),
            TextField(
              controller: categoryCtrl,
              decoration: const InputDecoration(labelText: 'Category'),
            ),
            TextField(
              controller: phoneCtrl,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: addressCtrl,
              decoration: const InputDecoration(labelText: 'Address'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                await BusinessController.createBusiness(
                  name: nameCtrl.text,
                  category: categoryCtrl.text,
                  phone: phoneCtrl.text,
                  address: addressCtrl.text,
                );

                Navigator.pushReplacementNamed(
                    context, RouteNames.dashboard);
              },
              child: const Text('Save Business'),
            ),
          ],
        ),
      ),
    );
  }
}
