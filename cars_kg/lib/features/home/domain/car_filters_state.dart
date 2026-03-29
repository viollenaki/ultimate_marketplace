import '../../../data/mock/mock_models.dart';

/// Active vehicle filters (client-side until search API exists).
class CarFiltersState {
  const CarFiltersState({
    this.brands = const {},
    this.minPrice,
    this.maxPrice,
    this.minYear,
    this.maxYear,
    this.minMileage,
    this.maxMileage,
    this.fuelTypes = const {},
    this.bodyTypes = const {},
    this.exteriorColors = const {},
    this.interiorColors = const {},
    this.transmissions = const {},
    this.requireNoAccident = false,
    this.maxDistanceKm,
    this.openToTradeOnly = false,
    this.sellerType = SellerFilterType.any,
  });

  final Set<String> brands;
  final double? minPrice;
  final double? maxPrice;
  final int? minYear;
  final int? maxYear;
  final int? minMileage;
  final int? maxMileage;
  final Set<String> fuelTypes;
  final Set<String> bodyTypes;
  final Set<String> exteriorColors;
  final Set<String> interiorColors;
  final Set<String> transmissions;
  final bool requireNoAccident;
  final double? maxDistanceKm;
  final bool openToTradeOnly;
  final SellerFilterType sellerType;

  static const CarFiltersState initial = CarFiltersState();

  bool get hasAnyFilter =>
      brands.isNotEmpty ||
      minPrice != null ||
      maxPrice != null ||
      minYear != null ||
      maxYear != null ||
      minMileage != null ||
      maxMileage != null ||
      fuelTypes.isNotEmpty ||
      bodyTypes.isNotEmpty ||
      exteriorColors.isNotEmpty ||
      interiorColors.isNotEmpty ||
      transmissions.isNotEmpty ||
      requireNoAccident ||
      maxDistanceKm != null ||
      openToTradeOnly ||
      sellerType != SellerFilterType.any;

  CarFiltersState copyWith({
    Set<String>? brands,
    double? minPrice,
    double? maxPrice,
    int? minYear,
    int? maxYear,
    int? minMileage,
    int? maxMileage,
    Set<String>? fuelTypes,
    Set<String>? bodyTypes,
    Set<String>? exteriorColors,
    Set<String>? interiorColors,
    Set<String>? transmissions,
    bool? requireNoAccident,
    double? maxDistanceKm,
    bool? openToTradeOnly,
    SellerFilterType? sellerType,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMinYear = false,
    bool clearMaxYear = false,
    bool clearMinMileage = false,
    bool clearMaxMileage = false,
    bool clearMaxDistance = false,
  }) {
    return CarFiltersState(
      brands: brands ?? this.brands,
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      maxYear: clearMaxYear ? null : (maxYear ?? this.maxYear),
      minMileage: clearMinMileage ? null : (minMileage ?? this.minMileage),
      maxMileage: clearMaxMileage ? null : (maxMileage ?? this.maxMileage),
      fuelTypes: fuelTypes ?? this.fuelTypes,
      bodyTypes: bodyTypes ?? this.bodyTypes,
      exteriorColors: exteriorColors ?? this.exteriorColors,
      interiorColors: interiorColors ?? this.interiorColors,
      transmissions: transmissions ?? this.transmissions,
      requireNoAccident: requireNoAccident ?? this.requireNoAccident,
      maxDistanceKm: clearMaxDistance ? null : (maxDistanceKm ?? this.maxDistanceKm),
      openToTradeOnly: openToTradeOnly ?? this.openToTradeOnly,
      sellerType: sellerType ?? this.sellerType,
    );
  }
}

enum SellerFilterType { any, owner, dealer }

bool listingMatchesFilters(Listing listing, CarFiltersState s) {
  if (s.brands.isNotEmpty && !s.brands.contains(listing.brand)) {
    return false;
  }
  if (s.minPrice != null && listing.price < s.minPrice!) return false;
  if (s.maxPrice != null && listing.price > s.maxPrice!) return false;
  if (s.minYear != null && listing.year < s.minYear!) return false;
  if (s.maxYear != null && listing.year > s.maxYear!) return false;
  if (s.minMileage != null && listing.mileage < s.minMileage!) return false;
  if (s.maxMileage != null && listing.mileage > s.maxMileage!) return false;
  if (s.fuelTypes.isNotEmpty) {
    final f = listing.fuelType;
    if (f == null || !s.fuelTypes.contains(f)) return false;
  }
  if (s.bodyTypes.isNotEmpty) {
    final b = listing.bodyType;
    if (b == null || !s.bodyTypes.contains(b)) return false;
  }
  if (s.exteriorColors.isNotEmpty) {
    final c = listing.exteriorColor;
    if (c == null || !s.exteriorColors.contains(c)) return false;
  }
  if (s.interiorColors.isNotEmpty) {
    final c = listing.interiorColor;
    if (c == null || !s.interiorColors.contains(c)) return false;
  }
  if (s.transmissions.isNotEmpty) {
    final t = listing.transmission;
    if (t == null || !s.transmissions.contains(t)) return false;
  }
  if (s.requireNoAccident && listing.isCrashed) return false;
  if (s.openToTradeOnly && !listing.openToTrade) return false;
  if (s.sellerType == SellerFilterType.owner && listing.sellerIsDealer) {
    return false;
  }
  if (s.sellerType == SellerFilterType.dealer && !listing.sellerIsDealer) {
    return false;
  }
  return true;
}
