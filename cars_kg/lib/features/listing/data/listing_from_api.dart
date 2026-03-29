import '../../../data/mock/mock_models.dart';

Listing listingFromApiJson(
  Map<String, dynamic> j, {
  MarketplaceUser? ownerOverride,
}) {
  final media = j['media'] as List<dynamic>? ?? [];
  final urls = media
      .map((e) => (e as Map<String, dynamic>)['file_url'] as String)
      .toList();
  final cat = j['category'] as Map<String, dynamic>?;
  final catName = cat?['name'] as String? ?? '';
  final ownerId = '${j['owner_id']}';
  final owner = ownerOverride ??
      MarketplaceUser(
        id: ownerId,
        name: 'Seller',
        avatarUrl: 'https://i.pravatar.cc/180?u=$ownerId',
        city: j['city'] as String? ?? '',
      );

  return Listing(
    id: '${j['id']}',
    title: j['title'] as String,
    description: j['description'] as String,
    price: (j['price'] as num).toDouble(),
    currency: j['currency'] as String? ?? 'KGS',
    location: j['city'] as String,
    imageUrls: urls,
    category: catName,
    isFavorite: false,
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
    locationDisplayName: j['location_display_name'] as String?,
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
