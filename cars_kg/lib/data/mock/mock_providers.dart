import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/config/app_config.dart';
import 'mock_data.dart';
import 'mock_models.dart';

enum DemoLoadState { data, empty, error }

@Riverpod(keepAlive: true)
bool mockMode(Ref ref) => useMockData;

final mockModeProvider = Provider<bool>((ref) => mockMode(ref));

final homeFeedStateProvider = StateProvider<DemoLoadState>(
  (ref) => DemoLoadState.data,
);
final homeFeedPageProvider = StateProvider<int>((ref) => 1);
final homeFeedIsGridProvider = StateProvider<bool>((ref) => true);

final homeListingsProvider = FutureProvider<List<Listing>>((ref) async {
  final enabled = ref.watch(mockModeProvider);
  if (!enabled) {
    return [];
  }

  await Future<void>.delayed(const Duration(milliseconds: 650));
  final state = ref.watch(homeFeedStateProvider);
  if (state == DemoLoadState.error) {
    throw Exception('Mock loading error');
  }
  if (state == DemoLoadState.empty) {
    return [];
  }

  final page = ref.watch(homeFeedPageProvider);
  final count = min(page * 8, mockListings.length);
  return mockListings.take(count).toList();
});

final listingByIdProvider = Provider.family<Listing?, String>((ref, id) {
  for (final item in mockListings) {
    if (item.id == id) {
      return item;
    }
  }
  return null;
});

final inboxStateProvider = StateProvider<DemoLoadState>(
  (ref) => DemoLoadState.data,
);

final conversationsProvider = FutureProvider<List<ConversationPreview>>((
  ref,
) async {
  await Future<void>.delayed(const Duration(milliseconds: 420));
  final state = ref.watch(inboxStateProvider);
  if (state == DemoLoadState.error) {
    throw Exception('Could not load conversations');
  }
  if (state == DemoLoadState.empty) {
    return [];
  }
  return mockConversations;
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier(this.conversationId)
    : super(
        List<ChatMessage>.from(mockChatMessages[conversationId] ?? const []),
      );

  final String conversationId;

  void sendMessage(String text, {String? attachmentLabel}) {
    if (text.trim().isEmpty && attachmentLabel == null) {
      return;
    }
    final message = ChatMessage(
      id: 'm_${DateTime.now().microsecondsSinceEpoch}',
      senderId: currentUserId,
      text: text.trim(),
      sentAt: DateTime.now(),
      attachmentLabel: attachmentLabel,
    );
    state = [...state, message];
  }
}

final chatMessagesProvider =
    StateNotifierProvider.family<
      ChatMessagesNotifier,
      List<ChatMessage>,
      String
    >((ref, conversationId) => ChatMessagesNotifier(conversationId));

final favoritesStateProvider = StateProvider<DemoLoadState>(
  (ref) => DemoLoadState.data,
);

final favoriteListingsProvider = FutureProvider<List<Listing>>((ref) async {
  await Future<void>.delayed(const Duration(milliseconds: 350));
  final state = ref.watch(favoritesStateProvider);
  if (state == DemoLoadState.error) {
    throw Exception('Could not load favorites');
  }
  if (state == DemoLoadState.empty) {
    return [];
  }
  return mockListings.where((item) => item.isFavorite).toList();
});

final myListingsProvider = Provider<List<Listing>>((ref) {
  return mockListings.where((item) => item.owner.id == currentUserId).toList();
});

final promotionsProvider = Provider<List<PromotionPaymentEntry>>(
  (ref) => mockPayments,
);
