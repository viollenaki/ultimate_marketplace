import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../data/listing_api_service.dart';
import 'map_picker_screen.dart';
import 'providers/listing_api_providers.dart';
import 'providers/remote_listing_provider.dart';

/// Values match backend `FuelType`, `TransmissionType`, `BodyType` (string storage).
const _fuelApiValues = [
  'petrol',
  'diesel',
  'electric',
  'hybrid',
  'lpg',
  'other',
];

const _transmissionApiValues = [
  'manual',
  'automatic',
  'cvt',
  'semi_automatic',
];

const _bodyApiValues = [
  'sedan',
  'suv',
  'hatchback',
  'coupe',
  'convertible',
  'pickup',
  'minivan',
  'wagon',
  'other',
];

const _currencyValues = ['KGS', 'USD', 'EUR'];

String _humanizeApiValue(String v) {
  if (v == 'lpg') return 'LPG';
  if (v == 'suv') return 'SUV';
  return v.replaceAll('_', ' ').split(' ').map((w) {
    if (w.isEmpty) return w;
    return w[0].toUpperCase() + w.substring(1);
  }).join(' ');
}

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
  final _colorController = TextEditingController();
  final _engineVolumeController = TextEditingController();
  final _horsepowerController = TextEditingController();
  final _doorsController = TextEditingController();
  final _extraJsonController = TextEditingController();

  bool _submitting = false;
  bool _isCrashed = false;
  bool _hasWarranty = false;

  String _currency = 'KGS';
  String? _fuelType;
  String? _transmission;
  String? _bodyType;

  double? _pickedLat;
  double? _pickedLng;
  String? _pickedDisplayName;

  DateTime? _expiresAtUtc;

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
    _colorController.dispose();
    _engineVolumeController.dispose();
    _horsepowerController.dispose();
    _doorsController.dispose();
    _extraJsonController.dispose();
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

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final initial = _expiresAtUtc != null
        ? DateTime(_expiresAtUtc!.year, _expiresAtUtc!.month, _expiresAtUtc!.day)
        : now.add(const Duration(days: 30));
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365 * 5)),
    );
    if (d != null && mounted) {
      setState(() {
        _expiresAtUtc = DateTime.utc(d.year, d.month, d.day, 23, 59, 59);
      });
    }
  }

  void _clearExpiry() => setState(() => _expiresAtUtc = null);

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

  String _expirySummary() {
    if (_expiresAtUtc == null) return 'No expiry (optional)';
    final d = _expiresAtUtc!;
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')} (UTC end of day)';
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

    final engineVol = _engineVolumeController.text.trim().isEmpty
        ? null
        : double.tryParse(_engineVolumeController.text.trim());
    if (_engineVolumeController.text.trim().isNotEmpty &&
        engineVol == null) {
      showNotReadySnackBar(context, 'Engine volume must be a number');
      return;
    }

    final hp = _horsepowerController.text.trim().isEmpty
        ? null
        : int.tryParse(_horsepowerController.text.trim());
    if (_horsepowerController.text.trim().isNotEmpty && hp == null) {
      showNotReadySnackBar(context, 'Horsepower must be a whole number');
      return;
    }

    final doors = _doorsController.text.trim().isEmpty
        ? null
        : int.tryParse(_doorsController.text.trim());
    if (_doorsController.text.trim().isNotEmpty && doors == null) {
      showNotReadySnackBar(context, 'Doors must be a whole number');
      return;
    }

    final extraRaw = _extraJsonController.text.trim();
    Object? extraDecoded;
    if (extraRaw.isNotEmpty) {
      try {
        final v = jsonDecode(extraRaw);
        if (v is Map) {
          extraDecoded = Map<String, dynamic>.from(v);
        } else if (v is List) {
          extraDecoded = List<dynamic>.from(v);
        } else {
          showNotReadySnackBar(
            context,
            'Extra JSON must be an object {} or array []',
          );
          return;
        }
      } catch (_) {
        showNotReadySnackBar(context, 'Extra JSON is not valid');
        return;
      }
    }

    final body = <String, dynamic>{
      'title': title,
      'description': description,
      'price': price,
      'currency': _currency,
      'city': city,
      'brand': brand,
      'model': model,
      'year': year,
      'mileage': mileage,
      'is_crashed': _isCrashed,
      'has_warranty': _hasWarranty,
    };

    if (_fuelType != null) {
      body['fuel_type'] = _fuelType;
    }
    if (_transmission != null) {
      body['transmission'] = _transmission;
    }
    if (_bodyType != null) {
      body['body_type'] = _bodyType;
    }
    final color = _colorController.text.trim();
    if (color.isNotEmpty) {
      body['color'] = color.length > 50 ? color.substring(0, 50) : color;
    }
    if (engineVol != null) {
      body['engine_volume'] = engineVol;
    }
    if (hp != null) {
      body['horsepower'] = hp;
    }
    if (doors != null) {
      body['doors'] = doors;
    }
    if (_pickedLat != null && _pickedLng != null) {
      body['latitude'] = _pickedLat;
      body['longitude'] = _pickedLng;
      final dn = _pickedDisplayName?.trim();
      if (dn != null && dn.isNotEmpty) {
        body['location_display_name'] =
            dn.length > 255 ? dn.substring(0, 255) : dn;
      }
    }
    if (_expiresAtUtc != null) {
      body['expires_at'] = _expiresAtUtc!.toIso8601String();
    }
    if (extraDecoded != null) {
      body['additional_attributes'] = extraDecoded;
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

  Widget _sectionTitle(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
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
                  label: Text(
                    _photos.isEmpty ? 'Add photos' : '${_photos.length} photos',
                  ),
                  onPressed: _pickPhotos,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Basics'),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title *'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price *'),
            ),
            const SizedBox(height: 8),
            Text(
              'Currency',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in _currencyValues)
                  ChoiceChip(
                    label: Text(c),
                    selected: _currency == c,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _currency = c),
                  ),
              ],
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
            const SizedBox(height: 16),
            _sectionTitle(context, 'Vehicle details'),
            Text(
              'Fuel type',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('—'),
                  selected: _fuelType == null,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _fuelType = null),
                ),
                for (final v in _fuelApiValues)
                  ChoiceChip(
                    label: Text(_humanizeApiValue(v)),
                    selected: _fuelType == v,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _fuelType = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Transmission',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('—'),
                  selected: _transmission == null,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _transmission = null),
                ),
                for (final v in _transmissionApiValues)
                  ChoiceChip(
                    label: Text(_humanizeApiValue(v)),
                    selected: _transmission == v,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _transmission = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Body type',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ChoiceChip(
                  label: const Text('—'),
                  selected: _bodyType == null,
                  onSelected: _submitting
                      ? null
                      : (_) => setState(() => _bodyType = null),
                ),
                for (final v in _bodyApiValues)
                  ChoiceChip(
                    label: Text(_humanizeApiValue(v)),
                    selected: _bodyType == v,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _bodyType = v),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _colorController,
              decoration: const InputDecoration(
                labelText: 'Exterior color',
                hintText: 'e.g. white, silver',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _engineVolumeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Engine volume (L)',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _horsepowerController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Horsepower',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _doorsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Doors',
                hintText: 'Optional',
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Previously crashed / damaged'),
              value: _isCrashed,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _isCrashed = v),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Has warranty'),
              value: _hasWarranty,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _hasWarranty = v),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Location'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Map location'),
              subtitle: Text(_locationSummary()),
              trailing: const Icon(Icons.map_outlined),
              onTap: _submitting ? null : _openMapPicker,
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Listing expiry'),
              subtitle: Text(_expirySummary()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiresAtUtc != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _submitting ? null : _clearExpiry,
                      tooltip: 'Clear',
                    ),
                  IconButton(
                    icon: const Icon(Icons.event_outlined),
                    onPressed: _submitting ? null : _pickExpiryDate,
                    tooltip: 'Pick date',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Description'),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description *'),
            ),
            const SizedBox(height: 16),
            _sectionTitle(context, 'Extra (advanced)'),
            TextField(
              controller: _extraJsonController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional attributes (JSON)',
                hintText: r'Optional object or array, e.g. {"trim":"Sport"}',
                alignLabelWithHint: true,
              ),
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
