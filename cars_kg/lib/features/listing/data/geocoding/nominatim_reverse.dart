import 'package:dio/dio.dart';

/// Reverse geocode via [Nominatim](https://nominatim.org/) (read-only).
/// Not the OSM editing API — suitable for display names after picking a point.
class NominatimReverse {
  NominatimReverse._();

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://nominatim.openstreetmap.org',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: const {
        'User-Agent': 'cars_kg/1.0 (contact: marketplace dev)',
        'Accept': 'application/json',
      },
    ),
  );

  static Future<String?> displayNameFor(double latitude, double longitude) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/reverse',
      queryParameters: <String, dynamic>{
        'lat': latitude,
        'lon': longitude,
        'format': 'json',
      },
    );
    final name = response.data?['display_name'];
    return name is String ? name : null;
  }
}
