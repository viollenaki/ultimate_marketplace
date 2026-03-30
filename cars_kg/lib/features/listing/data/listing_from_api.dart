import '../../../data/mock/mock_models.dart';

/// Parses int fields from JSON (handles int, double, numeric string; snake or camel keys).
String? _stringOrNull(dynamic v) {
  if (v is String) {
    return v;
  }
  return null;
}

int _readListingInt(Map<String, dynamic> j, String snake, String camel) {
  final v = j[snake] ?? j[camel];
  if (v == null) {
    return 0;
  }
  if (v is int) {
    return v;
  }
  if (v is num) {
    return v.toInt();
  }
  if (v is String) {
    return int.tryParse(v.trim()) ?? 0;
  }
  return 0;
}

MarketplaceUser _ownerFromListingJson(
  Map<String, dynamic> j,
  Map<String, dynamic>? ownerJson,
  String ownerId,
) {
  final listingCity = j['city'] as String? ?? '';
  if (ownerJson == null) {
    return MarketplaceUser(
      id: ownerId,
      name: 'Seller',
      avatarUrl: '',
      city: listingCity,
    );
  }
  final fullName = (ownerJson['full_name'] as String?)?.trim() ?? '';
  final ownerCity = (ownerJson['city'] as String?)?.trim() ?? '';
  final avatar =
      (ownerJson['profile_image_url'] as String?)?.trim() ?? '';
  return MarketplaceUser(
    id: '${ownerJson['id']}',
    name: fullName.isNotEmpty ? fullName : 'Seller',
    avatarUrl: avatar,
    city: ownerCity.isNotEmpty ? ownerCity : listingCity,
  );
}

Listing listingFromApiJson(
  Map<String, dynamic> j, {
  MarketplaceUser? ownerOverride,
  bool isFavorite = false,
}) {
  final media = j['media'] as List<dynamic>? ?? [];
  final urls = media
      .map((e) => (e as Map<String, dynamic>)['file_url'] as String?)
      .whereType<String>()
      .toList();
  final ownerId = '${j['owner_id']}';
  final ownerJson = j['owner'] as Map<String, dynamic>?;
  final owner = ownerOverride ??
      _ownerFromListingJson(j, ownerJson, ownerId);

  return Listing(
    id: '${j['id']}',
    title: j['title'] as String,
    description: j['description'] as String,
    price: (j['price'] as num).toDouble(),
    currency: j['currency'] as String? ?? 'KGS',
    location: j['city'] as String,
    imageUrls: urls,
    isFavorite: isFavorite,
    owner: owner,
    createdAt: DateTime.now(),
    brand: j['brand'] as String? ?? '',
    model: j['model'] as String? ?? '',
    year: (j['year'] as num?)?.toInt() ?? 0,
    mileage: (j['mileage'] as num?)?.toInt() ?? 0,
    fuelType: j['fuel_type'] as String?,
    transmission: j['transmission'] as String?,
    bodyType: j['body_type'] as String?,
    exteriorColor: j['color'] as String?,
    isCrashed: j['is_crashed'] as bool? ?? false,
    latitude: (j['latitude'] as num?)?.toDouble(),
    longitude: (j['longitude'] as num?)?.toDouble(),
    locationDisplayName: _stringOrNull(
      j['location_display_name'] ?? j['locationDisplayName'],
    ),
    viewCount: _readListingInt(j, 'view_count', 'viewCount'),
    favoriteCount: _readListingInt(j, 'favorite_count', 'favoriteCount'),
  );
}

/// Map UI model to API PATCH body (only non-null entries).
Map<String, dynamic> listingToPatchJson({
  String? title,
  String? description,
  double? price,
  String? currency,
  String? city,
  double? latitude,
  double? longitude,
  String? locationDisplayName,
}) {
  final m = <String, dynamic>{};
  if (title != null) {
    m['title'] = title;
  }
  if (description != null) {
    m['description'] = description;
  }
  if (price != null) {
    m['price'] = price;
  }
  if (currency != null) {
    m['currency'] = currency;
  }
  if (city != null) {
    m['city'] = city;
  }
  if (latitude != null) {
    m['latitude'] = latitude;
  }
  if (longitude != null) {
    m['longitude'] = longitude;
  }
  if (locationDisplayName != null) {
    m['location_display_name'] = locationDisplayName;
  }
  return m;
}
