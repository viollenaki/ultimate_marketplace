import 'package:flutter/material.dart';

import '../../../shared/widgets/app_snackbar.dart';

class EditListingScreen extends StatelessWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: 'Toyota Camry 70, 2019'),
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: '19800'),
              decoration: const InputDecoration(labelText: 'Price'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: 'Bishkek'),
              decoration: const InputDecoration(labelText: 'Location'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(
                text:
                    'Excellent condition. Full service history and clean documents.',
              ),
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => showNotReadySnackBar(
                context,
                'Update flow for $listingId will be connected with backend later',
              ),
              child: const Text('Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
