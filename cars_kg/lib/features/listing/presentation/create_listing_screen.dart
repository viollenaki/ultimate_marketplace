import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../data/listing_api_service.dart';
import 'map_picker_screen.dart';
import 'providers/listing_api_providers.dart';
import 'providers/remote_listing_provider.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  const CreateListingScreen({super.key});

  @override
  ConsumerState<CreateListingScreen> createState() =>
      _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController(text: 'Bishkek');
  final _descriptionController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController(text: '2020');
  final _mileageController = TextEditingController(text: '0');

  bool _submitting = false;

  double? _pickedLat;
  double? _pickedLng;
  String? _pickedDisplayName;

  final List<XFile> _photos = [];

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _mileageController.dispose();
    super.dispose();
  }

  Future<void> _openMapPicker() async {
    final result = await context.push<MapPickResult>(
      '/listing/map-picker',
      extra: <String, double?>{
        'lat': _pickedLat,
        'lng': _pickedLng,
      },
    );
    if (result != null && mounted) {
      setState(() {
        _pickedLat = result.latitude;
        _pickedLng = result.longitude;
        _pickedDisplayName = result.displayName;
      });
    }
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();
    final files = await picker.pickMultiImage();
    if (files.isEmpty || !mounted) {
      return;
    }
    setState(() {
      _photos
        ..clear()
        ..addAll(files.take(8));
    });
  }

  String _locationSummary() {
    if (_pickedLat != null && _pickedLng != null) {
      final name = _pickedDisplayName;
      if (name != null && name.isNotEmpty) {
        final short =
            name.length > 48 ? '${name.substring(0, 45)}…' : name;
        return short;
      }
      return '${_pickedLat!.toStringAsFixed(5)}, ${_pickedLng!.toStringAsFixed(5)}';
    }
    return 'Not set — tap to choose on map';
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final price = double.tryParse(_priceController.text.trim());
    final year = int.tryParse(_yearController.text.trim());
    final mileage = int.tryParse(_mileageController.text.trim());
    final brand = _brandController.text.trim();
    final model = _modelController.text.trim();
    final city = _cityController.text.trim();
    final description = _descriptionController.text.trim();

    if (title.isEmpty ||
        brand.isEmpty ||
        model.isEmpty ||
        city.isEmpty ||
        description.isEmpty) {
      showNotReadySnackBar(context, 'Please fill all required fields');
      return;
    }
    if (price == null || price <= 0) {
      showNotReadySnackBar(context, 'Enter a valid price');
      return;
    }
    if (year == null || mileage == null) {
      showNotReadySnackBar(context, 'Enter year and mileage');
      return;
    }

    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'currency': 'KGS',
      'city': city,
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
    };
    if (_pickedLat != null && _pickedLng != null) {
      body['latitude'] = _pickedLat;
      body['longitude'] = _pickedLng;
      final dn = _pickedDisplayName?.trim();
      if (dn != null && dn.isNotEmpty) {
        body['location_display_name'] = dn.length > 255 ? dn.substring(0, 255) : dn;
      }
    }

    setState(() => _submitting = true);
    try {
      final api = ref.read(listingApiServiceProvider);
      final created = await api.createListing(body);
      final id = (created['id'] as num).toInt();
      for (final photo in _photos) {
        await api.uploadListingImage(id, photo);
      }
      ref.invalidate(myRemoteListingsProvider);
      if (!mounted) {
        return;
      }
      showNotReadySnackBar(context, 'Listing created');
      context.go('/my-listings');
    } on ListingApiException catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, 'Failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Photos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(_photos.isEmpty ? 'Add photos' : '${_photos.length} photos'),
                  onPressed: _pickPhotos,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (KGS) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _brandController,
              decoration: const InputDecoration(labelText: 'Brand *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _modelController,
              decoration: const InputDecoration(labelText: 'Model *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _yearController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Year *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _mileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Mileage (km) *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City *'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Map location'),
              subtitle: Text(_locationSummary()),
              trailing: const Icon(Icons.map_outlined),
              onTap: _openMapPicker,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Publish listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
