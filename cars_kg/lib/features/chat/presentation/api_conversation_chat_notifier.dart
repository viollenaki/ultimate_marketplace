import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../data/mock/mock_models.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import '../data/chat_dtos.dart';
import '../data/conversation_chat_socket.dart';
import '../data/conversations_api.dart';

@immutable
class ApiConversationChatState {
  const ApiConversationChatState({
    this.messages = const [],
    this.isLoadingInitial = true,
    this.isLoadingOlder = false,
    this.socketConnected = false,
    this.bannerError,
    this.nextBeforeId,
  });

  final List<ChatMessage> messages;
  final bool isLoadingInitial;
  final bool isLoadingOlder;
  final bool socketConnected;
  final String? bannerError;
  final int? nextBeforeId;

  ApiConversationChatState copyWith({
    List<ChatMessage>? messages,
    bool? isLoadingInitial,
    bool? isLoadingOlder,
    bool? socketConnected,
    String? bannerError,
    bool clearBanner = false,
    int? nextBeforeId,
    bool clearNextBefore = false,
  }) {
    return ApiConversationChatState(
      messages: messages ?? this.messages,
      isLoadingInitial: isLoadingInitial ?? this.isLoadingInitial,
      isLoadingOlder: isLoadingOlder ?? this.isLoadingOlder,
      socketConnected: socketConnected ?? this.socketConnected,
      bannerError: clearBanner ? null : (bannerError ?? this.bannerError),
      nextBeforeId: clearNextBefore
          ? null
          : (nextBeforeId ?? this.nextBeforeId),
    );
  }
}

class ApiConversationChatNotifier
    extends StateNotifier<ApiConversationChatState> {
  ApiConversationChatNotifier(this.ref, this.conversationIdStr)
      : super(const ApiConversationChatState()) {
    ref.listen(authControllerProvider, (previous, next) {
      final id = _conversationId;
      if (id == null) return;
      final jwt = next.jwt;
      if (jwt == null || jwt.isEmpty) return;
      if (previous?.jwt != jwt && !state.isLoadingInitial) {
        _connectSocket(id, jwt);
      }
    });
    _start();
  }

  final Ref ref;
  final String conversationIdStr;

  ConversationChatSocket? _socket;
  StreamSubscription<ChatWsEvent>? _wsSub;
  Timer? _pingTimer;

  int? get _conversationId => int.tryParse(conversationIdStr);

  void _start() {
    final id = _conversationId;
    if (id == null) {
      state = state.copyWith(
        isLoadingInitial: false,
        bannerError: 'Invalid conversation',
      );
      return;
    }
    Future<void>.microtask(() => _bootstrap(id));
  }

  Future<void> _bootstrap(int conversationId) async {
    final jwt = ref.read(authControllerProvider).jwt;
    if (jwt == null || jwt.isEmpty) {
      state = state.copyWith(
        isLoadingInitial: false,
        bannerError: 'Sign in to use chat',
      );
      return;
    }

    final dio = ref.read(authenticatedApiClientProvider).dio;
    try {
      final page = await fetchConversationMessages(dio, conversationId);
      state = state.copyWith(
        messages: page.messages.map(_toUiMessage).toList(),
        isLoadingInitial: false,
        nextBeforeId: page.nextBeforeId,
        clearBanner: true,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        bannerError: e.message ?? 'Could not load messages',
      );
      return;
    } catch (e) {
      state = state.copyWith(
        isLoadingInitial: false,
        bannerError: '$e',
      );
      return;
    }

    _connectSocket(conversationId, jwt);
  }

  ChatMessage _toUiMessage(ChatMessageDto dto) {
    return ChatMessage(
      id: '${dto.id}',
      senderId: '${dto.senderId}',
      text: dto.textBody ?? '',
      sentAt: dto.sentAt ?? DateTime.now(),
    );
  }

  void _connectSocket(int conversationId, String jwt) {
    _wsSub?.cancel();
    _wsSub = null;
    _socket?.dispose();
    _socket = null;
    _pingTimer?.cancel();

    final socket = ConversationChatSocket(
      conversationId: conversationId,
      accessToken: jwt,
    );
    _socket = socket;
    socket.connect();

    _wsSub = socket.events.listen(_onWsEvent);

    _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
      socket.ping();
    });
  }

  void _onWsEvent(ChatWsEvent event) {
    switch (event) {
      case ChatWsConnected():
        state = state.copyWith(socketConnected: true, clearBanner: true);
      case ChatWsErrorEvent(:final detail):
        state = state.copyWith(bannerError: detail);
      case ChatWsPong():
        break;
      case ChatWsNewMessage(:final message):
        final ui = _toUiMessage(message);
        final existing = state.messages.any((m) => m.id == ui.id);
        if (existing) return;
        state = state.copyWith(
          messages: [...state.messages, ui],
        );
      case ChatWsMessagesPage(:final page):
        final older = page.messages.map(_toUiMessage).toList();
        final merged = [...older, ...state.messages];
        final seen = <String>{};
        final deduped = <ChatMessage>[];
        for (final m in merged) {
          if (seen.add(m.id)) deduped.add(m);
        }
        deduped.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        state = state.copyWith(
          messages: deduped,
          nextBeforeId: page.nextBeforeId ?? state.nextBeforeId,
        );
      case ChatWsConnectionLost():
        state = state.copyWith(socketConnected: false);
    }
  }

  Future<void> loadOlder() async {
    final id = _conversationId;
    final before = state.nextBeforeId;
    if (id == null || before == null || state.isLoadingOlder) return;

    final dio = ref.read(authenticatedApiClientProvider).dio;
    state = state.copyWith(isLoadingOlder: true);
    try {
      final page = await fetchConversationMessages(
        dio,
        id,
        beforeId: before,
      );
      final older = page.messages.map(_toUiMessage).toList();
      final byId = {for (final m in [...older, ...state.messages]) m.id: m};
      final merged = byId.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      state = state.copyWith(
        messages: merged,
        isLoadingOlder: false,
        nextBeforeId: page.nextBeforeId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingOlder: false,
        bannerError: '$e',
      );
    }
  }

  void sendMessage(String text) {
    final t = text.trim();
    if (t.isEmpty) return;
    _socket?.sendMessage(t);
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _wsSub?.cancel();
    _socket?.dispose();
    super.dispose();
  }
}

final apiConversationChatProvider = StateNotifierProvider.autoDispose
    .family<ApiConversationChatNotifier, ApiConversationChatState, String>(
  (ref, conversationIdStr) => ApiConversationChatNotifier(ref, conversationIdStr),
);
