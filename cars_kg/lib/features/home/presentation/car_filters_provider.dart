import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/car_filters_state.dart';

class CarFiltersNotifier extends Notifier<CarFiltersState> {
  @override
  CarFiltersState build() => CarFiltersState.initial;

  void replace(CarFiltersState next) => state = next;

  void reset() => state = CarFiltersState.initial;
}

final carFiltersProvider =
    NotifierProvider<CarFiltersNotifier, CarFiltersState>(CarFiltersNotifier.new);
