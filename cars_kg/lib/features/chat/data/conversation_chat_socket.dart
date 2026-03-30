import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../core/config/env.dart';
import 'chat_dtos.dart';

/// Server → client frames (`event` field).
sealed class ChatWsEvent {
  const ChatWsEvent();
}

class ChatWsConnected extends ChatWsEvent {
  const ChatWsConnected({
    required this.conversationId,
    required this.userId,
  });

  final int conversationId;
  final int userId;
}

class ChatWsErrorEvent extends ChatWsEvent {
  const ChatWsErrorEvent(this.detail);

  final String detail;
}

class ChatWsPong extends ChatWsEvent {
  const ChatWsPong();
}

class ChatWsNewMessage extends ChatWsEvent {
  const ChatWsNewMessage(this.message);

  final ChatMessageDto message;
}

class ChatWsMessagesPage extends ChatWsEvent {
  const ChatWsMessagesPage(this.page);

  final ChatMessageListPage page;
}

/// Underlying socket closed or failed (triggers reconnect in service layer).
class ChatWsConnectionLost extends ChatWsEvent {
  const ChatWsConnectionLost([this.reason]);

  final Object? reason;
}

/// Low-level WebSocket aligned with FastAPI `/{conversation_id}/ws`.
class ConversationChatSocket {
  ConversationChatSocket({
    required this.conversationId,
    required this.accessToken,
  });

  final int conversationId;
  final String accessToken;

  final _events = StreamController<ChatWsEvent>.broadcast();
  Stream<ChatWsEvent> get events => _events.stream;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _reconnectTimer;
  bool _disposeRequested = false;
  int _reconnectAttempt = 0;
  static const int _maxAttempts = 12;

  static const Duration _baseReconnectDelay = Duration(seconds: 2);

  Uri get _uri => Env.conversationWebSocketUri(conversationId, accessToken);

  void connect() {
    if (_disposeRequested || accessToken.isEmpty) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;

    WebSocketChannel ch;
    try {
      ch = WebSocketChannel.connect(_uri);
    } catch (e) {
      _events.add(ChatWsErrorEvent('connect failed: $e'));
      _scheduleReconnect();
      return;
    }
    _channel = ch;

    _subscription = ch.stream.listen(
      _onRaw,
      onError: (Object e, StackTrace _) {
        _events.add(ChatWsConnectionLost(e));
        _scheduleReconnect();
      },
      onDone: () {
        if (_disposeRequested) return;
        _events.add(const ChatWsConnectionLost());
        _scheduleReconnect();
      },
      cancelOnError: false,
    );
  }

  void _onRaw(dynamic raw) {
    if (raw is! String) {
      _events.add(const ChatWsErrorEvent('non-text frame'));
      return;
    }
    Map<String, dynamic>? map;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      }
    } catch (_) {
      _events.add(ChatWsErrorEvent('invalid json: ${raw.length > 80 ? '${raw.substring(0, 80)}…' : raw}'));
      return;
    }
    if (map == null) {
      _events.add(const ChatWsErrorEvent('json must be an object'));
      return;
    }

    final event = map['event'] as String?;
    switch (event) {
      case 'connected':
        _reconnectAttempt = 0;
        final cid = (map['conversation_id'] as num?)?.toInt() ?? conversationId;
        final uid = (map['user_id'] as num?)?.toInt() ?? 0;
        _events.add(ChatWsConnected(conversationId: cid, userId: uid));
      case 'error':
        final d = map['detail'];
        _events.add(ChatWsErrorEvent(d is String ? d : '$d'));
      case 'pong':
        _events.add(const ChatWsPong());
      case 'new_message':
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          final m = ChatMessageDto.fromJson(data);
          if (m != null) {
            _events.add(ChatWsNewMessage(m));
          }
        }
      case 'messages_page':
        final data = map['data'];
        if (data is Map<String, dynamic>) {
          _events.add(ChatWsMessagesPage(ChatMessageListPage.fromJson(data)));
        }
      case null:
        break;
      default:
        _events.add(ChatWsErrorEvent('unknown event: $event'));
    }
  }

  void _scheduleReconnect() {
    if (_disposeRequested) return;
    if (_reconnectTimer != null) return;
    if (_reconnectAttempt >= _maxAttempts) {
      _events.add(const ChatWsErrorEvent('reconnect limit reached'));
      return;
    }
    _reconnectAttempt++;
    final delay = _baseReconnectDelay * _reconnectAttempt;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay > const Duration(seconds: 30)
        ? const Duration(seconds: 30)
        : delay, () {
      _reconnectTimer = null;
      connect();
    });
  }

  void sendJson(Map<String, dynamic> payload) {
    final ch = _channel;
    if (ch == null) return;
    try {
      ch.sink.add(jsonEncode(payload));
    } catch (e) {
      _events.add(ChatWsErrorEvent('send failed: $e'));
    }
  }

  void ping() => sendJson({'action': 'ping'});

  void sendMessage(String textBody) {
    sendJson({'action': 'send_message', 'text_body': textBody});
  }

  void fetchMessages({int limit = 50, int? beforeId}) {
    final m = <String, dynamic>{
      'action': 'fetch_messages',
      'limit': limit,
    };
    if (beforeId != null) {
      m['before_id'] = beforeId;
    }
    sendJson(m);
  }

  void dispose() {
    _disposeRequested = true;
    _reconnectTimer?.cancel();
    unawaited(_subscription?.cancel());
    _subscription = null;
    try {
      _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    if (!_events.isClosed) {
      _events.close();
    }
  }
}
