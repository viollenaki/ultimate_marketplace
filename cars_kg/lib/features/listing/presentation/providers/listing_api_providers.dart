import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/listing_api_service.dart';

final listingApiServiceProvider = Provider<ListingApiService>((ref) {
  return ListingApiService(ref.watch(authenticatedApiClientProvider));
});
