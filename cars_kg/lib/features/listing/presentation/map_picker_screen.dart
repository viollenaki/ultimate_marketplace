import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import '../data/geocoding/nominatim_reverse.dart';

/// Result of [MapPickerScreen] — coordinates to send as `latitude` / `longitude`
/// on listing create/update. [displayName] comes from Nominatim reverse lookup.
class MapPickResult {
  MapPickResult({
    required this.latitude,
    required this.longitude,
    this.displayName,
  });

  final double latitude;
  final double longitude;
  final String? displayName;
}

/// Map UI uses public [OSM raster tiles](https://wiki.openstreetmap.org/wiki/API)
/// (not the OSM editing API). Tiles: usage policy applies; app identifies as `cars_kg`.
class MapPickerScreen extends StatefulWidget {
  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static final LatLng _bishkek = LatLng(42.8746, 74.5698);

  late LatLng _markerPoint;
  bool _loadingName = false;

  @override
  void initState() {
    super.initState();
    final lat = widget.initialLatitude;
    final lng = widget.initialLongitude;
    if (lat != null && lng != null) {
      _markerPoint = LatLng(lat, lng);
    } else {
      _markerPoint = _bishkek;
    }
  }

  Future<void> _confirm() async {
    setState(() => _loadingName = true);
    String? displayName;
    try {
      displayName = await NominatimReverse.displayNameFor(
        _markerPoint.latitude,
        _markerPoint.longitude,
      );
    } catch (_) {
      /* optional */
    }
    if (!mounted) {
      return;
    }
    setState(() => _loadingName = false);
    context.pop(
      MapPickResult(
        latitude: _markerPoint.latitude,
        longitude: _markerPoint.longitude,
        displayName: displayName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick location on map'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _loadingName ? null : _confirm,
            child: _loadingName
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('USE THIS POINT'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Tap the map to move the pin. OpenStreetMap tiles © OpenStreetMap contributors.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                initialCenter: _markerPoint,
                initialZoom: 13,
                onTap: (tapPosition, latLng) {
                  setState(() => _markerPoint = latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'cars_kg',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _markerPoint,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_on,
                        size: 48,
                        color: Color(0xFFC62828),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
