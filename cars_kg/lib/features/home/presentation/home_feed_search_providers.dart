import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Debounced search text sent to `GET /listings` as `q` (mock mode ignores this).
class HomeFeedSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String value) => state = value;
}

final homeFeedSearchQueryProvider =
    NotifierProvider<HomeFeedSearchQueryNotifier, String>(
  HomeFeedSearchQueryNotifier.new,
);
