import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/mock/mock_data.dart';
import '../../../../data/mock/mock_models.dart';
import '../../data/listing_from_api.dart';
import 'listing_api_providers.dart';

final myRemoteListingsProvider =
    FutureProvider.autoDispose<List<Listing>>((ref) async {
  final api = ref.watch(listingApiServiceProvider);
  final raw = await api.fetchMyListings();
  return raw
      .map(
        (e) => listingFromApiJson(
          e,
          ownerOverride: currentUser,
        ),
      )
      .toList();
});

final remoteListingProvider =
    FutureProvider.autoDispose.family<Listing, int>((ref, id) async {
  final api = ref.watch(listingApiServiceProvider);
  final j = await api.getListing(id);
  return listingFromApiJson(j);
});
