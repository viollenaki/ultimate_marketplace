import 'package:flutter/foundation.dart';

/// Parsed `MessageResponse` / `new_message` payload from the API.
@immutable
class ChatMessageDto {
  const ChatMessageDto({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.textBody,
    required this.sentAt,
    this.senderName,
    this.senderAvatarUrl,
  });

  final int id;
  final int conversationId;
  final int senderId;
  final String? textBody;
  final DateTime? sentAt;
  final String? senderName;
  final String? senderAvatarUrl;

  static ChatMessageDto? fromJson(Map<String, dynamic>? j) {
    if (j == null) return null;
    final id = (j['id'] as num?)?.toInt();
    if (id == null) return null;
    return ChatMessageDto(
      id: id,
      conversationId: (j['conversation_id'] as num?)?.toInt() ?? 0,
      senderId: (j['sender_id'] as num?)?.toInt() ?? 0,
      textBody: j['text_body'] as String?,
      sentAt: _parseDate(j['sent_at']),
      senderName: (j['sender'] is Map)
          ? ((j['sender'] as Map)['full_name'] as String?)
          : null,
      senderAvatarUrl: (j['sender'] is Map)
          ? ((j['sender'] as Map)['profile_image_url'] as String?)
          : null,
    );
  }

  static DateTime? _parseDate(Object? v) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v);
    }
    return null;
  }
}

/// `MessageListResponse` from REST or `messages_page` over WebSocket.
@immutable
class ChatMessageListPage {
  const ChatMessageListPage({
    required this.messages,
    this.nextBeforeId,
  });

  final List<ChatMessageDto> messages;
  final int? nextBeforeId;

  static ChatMessageListPage fromJson(Map<String, dynamic> j) {
    final raw = j['messages'] as List<dynamic>? ?? [];
    final messages = <ChatMessageDto>[];
    for (final e in raw) {
      if (e is Map<String, dynamic>) {
        final m = ChatMessageDto.fromJson(e);
        if (m != null) messages.add(m);
      }
    }
    final next = j['next_before_id'];
    return ChatMessageListPage(
      messages: messages,
      nextBeforeId: next is num ? next.toInt() : null,
    );
  }
}
