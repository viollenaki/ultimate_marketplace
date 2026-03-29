import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_snackbar.dart';
import '../data/listing_api_service.dart';
import '../data/listing_from_api.dart';
import 'map_picker_screen.dart';
import 'providers/listing_api_providers.dart';
import 'providers/remote_listing_provider.dart';

class EditListingScreen extends ConsumerStatefulWidget {
  const EditListingScreen({super.key, required this.listingId});

  final String listingId;

  @override
  ConsumerState<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends ConsumerState<EditListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _descriptionController = TextEditingController();

  int? _numericId;
  bool _loading = true;
  bool _saving = false;
  double? _pickedLat;
  double? _pickedLng;
  String? _pickedDisplayName;

  @override
  void initState() {
    super.initState();
    _numericId = int.tryParse(widget.listingId);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final id = _numericId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final api = ref.read(listingApiServiceProvider);
      final j = await api.getListing(id);
      if (!mounted) {
        return;
      }
      _titleController.text = j['title'] as String? ?? '';
      _priceController.text = '${j['price']}';
      _cityController.text = j['city'] as String? ?? '';
      _descriptionController.text = j['description'] as String? ?? '';
      _pickedLat = (j['latitude'] as num?)?.toDouble();
      _pickedLng = (j['longitude'] as num?)?.toDouble();
      _pickedDisplayName = j['location_display_name'] as String?;
      setState(() => _loading = false);
    } on ListingApiException catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showNotReadySnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showNotReadySnackBar(context, '$e');
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openMap() async {
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

  String _locationSummary() {
    if (_pickedLat != null && _pickedLng != null) {
      final name = _pickedDisplayName;
      if (name != null && name.isNotEmpty) {
        return name.length > 48 ? '${name.substring(0, 45)}…' : name;
      }
      return '${_pickedLat!.toStringAsFixed(5)}, ${_pickedLng!.toStringAsFixed(5)}';
    }
    return 'Not set';
  }

  Future<void> _save() async {
    final id = _numericId;
    if (id == null) {
      showNotReadySnackBar(context, 'Invalid listing id');
      return;
    }
    final price = double.tryParse(_priceController.text.trim());
    if (price == null || price <= 0) {
      showNotReadySnackBar(context, 'Enter a valid price');
      return;
    }
    final patch = listingToPatchJson(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      price: price,
      currency: 'KGS',
      city: _cityController.text.trim(),
      latitude: _pickedLat,
      longitude: _pickedLng,
      locationDisplayName: _pickedDisplayName,
    );
    if (patch.isEmpty) {
      showNotReadySnackBar(context, 'Nothing to update');
      return;
    }
    setState(() => _saving = true);
    try {
      final api = ref.read(listingApiServiceProvider);
      await api.updateListing(id, patch);
      ref.invalidate(myRemoteListingsProvider);
      ref.invalidate(remoteListingProvider(id));
      if (!mounted) {
        return;
      }
      showNotReadySnackBar(context, 'Saved');
      context.pop();
    } on ListingApiException catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, e.message);
      }
    } catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, '$e');
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = _numericId;
    if (id == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit listing')),
        body: const Center(
          child: Text('This listing cannot be edited from the server.'),
        ),
      );
    }
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit listing')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Edit listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _priceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Price (KGS)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'City'),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Map location'),
              subtitle: Text(_locationSummary()),
              trailing: const Icon(Icons.map_outlined),
              onTap: _openMap,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
