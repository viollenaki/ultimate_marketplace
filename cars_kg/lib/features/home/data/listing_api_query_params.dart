import '../domain/car_filters_state.dart';

/// Maps filter UI labels to backend enum / stored strings (see `FuelType`, `BodyType`, etc.).
String? _mapFuel(String ui) {
  switch (ui) {
    case 'Gasoline':
      return 'petrol';
    case 'Diesel':
      return 'diesel';
    case 'Hybrid':
      return 'hybrid';
    case 'Electric':
      return 'electric';
    case 'LPG':
      return 'lpg';
    default:
      return null;
  }
}

String? _mapBody(String ui) {
  switch (ui) {
    case 'Sedan':
      return 'sedan';
    case 'SUV':
      return 'suv';
    case 'Hatchback':
      return 'hatchback';
    case 'Coupe':
      return 'coupe';
    case 'Wagon':
      return 'wagon';
    case 'Pickup':
      return 'pickup';
    case 'Minivan':
      return 'minivan';
    default:
      return null;
  }
}

String? _mapTransmission(String ui) {
  switch (ui) {
    case 'Manual':
      return 'manual';
    case 'Automatic':
      return 'automatic';
    case 'Tiptronic':
      return 'semi_automatic';
    default:
      return null;
  }
}

String? _mapColor(String ui) => ui.toLowerCase();

/// Query map for `GET /listings` (search + filters).
Map<String, dynamic> buildPublicListingsQuery({
  required int skip,
  required int limit,
  required String debouncedSearch,
  required CarFiltersState filters,
}) {
  final q = <String, dynamic>{
    'skip': skip,
    'limit': limit,
  };

  final trimmed = debouncedSearch.trim();
  if (trimmed.isNotEmpty) {
    q['q'] = trimmed;
  }

  if (filters.brands.isNotEmpty) {
    q['brands'] = filters.brands.join(',');
  }
  final city = filters.city?.trim();
  if (city != null && city.isNotEmpty) {
    q['city'] = city;
  }
  if (filters.minPrice != null) {
    q['price_min'] = filters.minPrice;
  }
  if (filters.maxPrice != null) {
    q['price_max'] = filters.maxPrice;
  }
  if (filters.minYear != null) {
    q['year_min'] = filters.minYear;
  }
  if (filters.maxYear != null) {
    q['year_max'] = filters.maxYear;
  }
  if (filters.minMileage != null) {
    q['mileage_min'] = filters.minMileage;
  }
  if (filters.maxMileage != null) {
    q['mileage_max'] = filters.maxMileage;
  }

  final fuels = filters.fuelTypes.map(_mapFuel).whereType<String>().toList();
  if (fuels.isNotEmpty) {
    q['fuel_types'] = fuels.join(',');
  }
  final bodies = filters.bodyTypes.map(_mapBody).whereType<String>().toList();
  if (bodies.isNotEmpty) {
    q['body_types'] = bodies.join(',');
  }
  final tr =
      filters.transmissions.map(_mapTransmission).whereType<String>().toList();
  if (tr.isNotEmpty) {
    q['transmissions'] = tr.join(',');
  }
  final colors =
      filters.exteriorColors.map(_mapColor).whereType<String>().toList();
  if (colors.isNotEmpty) {
    q['colors'] = colors.join(',');
  }
  if (filters.requireNoAccident) {
    q['require_no_accident'] = true;
  }

  return q;
}
