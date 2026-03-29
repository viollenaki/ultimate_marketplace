import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/localization/app_localizations.dart';
import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../domain/car_filters_state.dart';
import 'car_filters_provider.dart';

const _kFuels = ['Gasoline', 'Diesel', 'Hybrid', 'Electric', 'LPG'];
const _kBodies = ['Sedan', 'SUV', 'Hatchback', 'Coupe', 'Wagon'];
const _kTransmissions = ['Automatic', 'Manual', 'Tiptronic'];
const _kExtColors = ['White', 'Black', 'Silver', 'Gray', 'Blue', 'Red'];
const _kIntColors = ['Black', 'Beige', 'Gray', 'Brown'];

class CarFiltersScreen extends ConsumerStatefulWidget {
  const CarFiltersScreen({super.key});

  @override
  ConsumerState<CarFiltersScreen> createState() => _CarFiltersScreenState();
}

class _CarFiltersScreenState extends ConsumerState<CarFiltersScreen> {
  late CarFiltersState _draft;
  final _minPrice = TextEditingController();
  final _maxPrice = TextEditingController();
  final _minYear = TextEditingController();
  final _maxYear = TextEditingController();
  final _minMileage = TextEditingController();
  final _maxMileage = TextEditingController();
  final _maxDistance = TextEditingController();
  bool _seeded = false;

  @override
  void dispose() {
    _minPrice.dispose();
    _maxPrice.dispose();
    _minYear.dispose();
    _maxYear.dispose();
    _minMileage.dispose();
    _maxMileage.dispose();
    _maxDistance.dispose();
    super.dispose();
  }

  void _seedFromProvider() {
    final s = ref.read(carFiltersProvider);
    _draft = s;
    _minPrice.text = s.minPrice != null ? s.minPrice!.toStringAsFixed(0) : '';
    _maxPrice.text = s.maxPrice != null ? s.maxPrice!.toStringAsFixed(0) : '';
    _minYear.text = s.minYear?.toString() ?? '';
    _maxYear.text = s.maxYear?.toString() ?? '';
    _minMileage.text = s.minMileage?.toString() ?? '';
    _maxMileage.text = s.maxMileage?.toString() ?? '';
    _maxDistance.text = s.maxDistanceKm?.toStringAsFixed(0) ?? '';
  }

  double? _parseDoubleField(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  int? _parseIntField(String text) {
    final t = text.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  void _apply() {
    ref.read(carFiltersProvider.notifier).replace(
          CarFiltersState(
            brands: _draft.brands,
            minPrice: _parseDoubleField(_minPrice.text),
            maxPrice: _parseDoubleField(_maxPrice.text),
            minYear: _parseIntField(_minYear.text),
            maxYear: _parseIntField(_maxYear.text),
            minMileage: _parseIntField(_minMileage.text),
            maxMileage: _parseIntField(_maxMileage.text),
            fuelTypes: _draft.fuelTypes,
            bodyTypes: _draft.bodyTypes,
            exteriorColors: _draft.exteriorColors,
            interiorColors: _draft.interiorColors,
            transmissions: _draft.transmissions,
            requireNoAccident: _draft.requireNoAccident,
            maxDistanceKm: _parseDoubleField(_maxDistance.text),
            openToTradeOnly: _draft.openToTradeOnly,
            sellerType: _draft.sellerType,
          ),
        );
    context.pop();
  }

  void _resetAll() {
    ref.read(carFiltersProvider.notifier).reset();
    setState(() {
      _draft = CarFiltersState.initial;
      _minPrice.clear();
      _maxPrice.clear();
      _minYear.clear();
      _maxYear.clear();
      _minMileage.clear();
      _maxMileage.clear();
      _maxDistance.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!_seeded) {
      _seedFromProvider();
      _seeded = true;
    }

    return Scaffold(
      backgroundColor: AppPalette.surface,
      appBar: AppBar(
        title: Text(l10n.t('filtersTitle')),
        actions: [
          TextButton(
            onPressed: _resetAll,
            child: Text(
              l10n.t('filtersReset'),
              style: const TextStyle(color: AppPalette.textSecondary),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _sectionExpansion(
                  title: l10n.t('filterMakeModels'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: kAllBrands.map((b) {
                      final sel = _draft.brands.contains(b);
                      return FilterChip(
                        label: Text(b),
                        selected: sel,
                        onSelected: (_) => setState(() {
                          final next = Set<String>.from(_draft.brands);
                          if (sel) {
                            next.remove(b);
                          } else {
                            next.add(b);
                          }
                          _draft = _draft.copyWith(brands: next);
                        }),
                      );
                    }).toList(),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterPrice'),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minPrice,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterMinKgs'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxPrice,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterMaxKgs'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterMileage'),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minMileage,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterMinKm'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxMileage,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterMaxKm'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterYear'),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minYear,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterYearFrom'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _maxYear,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: l10n.t('filterYearTo'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterFuelType'),
                  child: _chipRow(
                    _kFuels,
                    _draft.fuelTypes,
                    (next) => setState(() => _draft = _draft.copyWith(fuelTypes: next)),
                  ),
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.t('filterSectionStyle'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterBodyType'),
                  child: _chipRow(
                    _kBodies,
                    _draft.bodyTypes,
                    (next) => setState(() => _draft = _draft.copyWith(bodyTypes: next)),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterInteriorColors'),
                  child: _chipRow(
                    _kIntColors,
                    _draft.interiorColors,
                    (next) =>
                        setState(() => _draft = _draft.copyWith(interiorColors: next)),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterExteriorColors'),
                  child: _chipRow(
                    _kExtColors,
                    _draft.exteriorColors,
                    (next) =>
                        setState(() => _draft = _draft.copyWith(exteriorColors: next)),
                  ),
                ),
                const Divider(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.t('filterSectionOthers'),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterTransmission'),
                  child: _chipRow(
                    _kTransmissions,
                    _draft.transmissions,
                    (next) =>
                        setState(() => _draft = _draft.copyWith(transmissions: next)),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterCondition'),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.t('filterNoAccident')),
                    value: _draft.requireNoAccident,
                    onChanged: (v) =>
                        setState(() => _draft = _draft.copyWith(requireNoAccident: v)),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterDistance'),
                  child: TextField(
                    controller: _maxDistance,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: l10n.t('filterMaxDistanceKm'),
                      helperText: l10n.t('filterDistanceHint'),
                    ),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterOpenToTrade'),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(l10n.t('filterOpenToTradeOnly')),
                    value: _draft.openToTradeOnly,
                    onChanged: (v) =>
                        setState(() => _draft = _draft.copyWith(openToTradeOnly: v)),
                  ),
                ),
                _sectionExpansion(
                  title: l10n.t('filterSellerType'),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: SellerFilterType.values.map((v) {
                      final label = switch (v) {
                        SellerFilterType.any => l10n.t('filterSellerAny'),
                        SellerFilterType.owner => l10n.t('filterSellerOwner'),
                        SellerFilterType.dealer => l10n.t('filterSellerDealer'),
                      };
                      final sel = _draft.sellerType == v;
                      return FilterChip(
                        label: Text(label),
                        selected: sel,
                        onSelected: (_) =>
                            setState(() => _draft = _draft.copyWith(sellerType: v)),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.primaryVariant,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _apply,
                  child: Text(
                    l10n.t('filtersApply'),
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionExpansion({required String title, required Widget child}) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppPalette.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _chipRow(
    List<String> options,
    Set<String> selected,
    void Function(Set<String>) onChanged,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((o) {
        final sel = selected.contains(o);
        return FilterChip(
          label: Text(o),
          selected: sel,
          onSelected: (_) {
            final next = Set<String>.from(selected);
            if (sel) {
              next.remove(o);
            } else {
              next.add(o);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }
}
