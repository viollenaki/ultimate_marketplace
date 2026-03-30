import 'package:dio/dio.dart';

import '../../../data/mock/mock_models.dart';
import 'chat_dtos.dart';

/// `POST /conversations` — creates or returns existing 1:1 thread (see FastAPI).
Future<int> createOrGetConversation(
  Dio dio, {
  required int otherUserId,
  int? listingId,
}) async {
  final body = <String, dynamic>{'other_user_id': otherUserId};
  if (listingId != null) {
    body['listing_id'] = listingId;
  }
  final r = await dio.post<Map<String, dynamic>>(
    '/conversations',
    data: body,
    options: Options(headers: {'Content-Type': 'application/json'}),
  );
  final data = r.data;
  final id = (data?['id'] as num?)?.toInt();
  if (id == null) {
    throw DioException(
      requestOptions: r.requestOptions,
      message: 'Missing conversation id in response',
    );
  }
  return id;
}

String conversationCreateErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is Map && detail['error'] is String) {
      return detail['error'] as String;
    }
    if (detail is String) {
      return detail;
    }
  }
  return e.message ?? 'Could not start conversation';
}

Future<ChatMessageListPage> fetchConversationMessages(
  Dio dio,
  int conversationId, {
  int limit = 50,
  int? beforeId,
}) async {
  final query = <String, dynamic>{'limit': limit};
  if (beforeId != null) {
    query['before_id'] = beforeId;
  }
  final r = await dio.get<Map<String, dynamic>>(
    '/conversations/$conversationId/messages',
    queryParameters: query,
  );
  final data = r.data;
  if (data == null) {
    throw DioException(
      requestOptions: r.requestOptions,
      message: 'Empty messages response',
    );
  }
  return ChatMessageListPage.fromJson(data);
}

/// Maps `GET /conversations` entries to inbox [ConversationPreview].
Future<List<ConversationPreview>> fetchConversationsForInbox(Dio dio) async {
  final r = await dio.get<Map<String, dynamic>>('/conversations');
  final data = r.data;
  if (data == null) return [];
  final raw = data['conversations'] as List<dynamic>? ?? [];
  final out = <ConversationPreview>[];
  for (final e in raw) {
    if (e is! Map<String, dynamic>) continue;
    final id = (e['id'] as num?)?.toInt();
    if (id == null) continue;
    final other = e['other_user'];
    if (other is! Map<String, dynamic>) continue;
    final oid = (other['id'] as num?)?.toInt();
    if (oid == null) continue;
    final preview = e['last_message_preview'] as String? ?? '';
    final at = _parseDate(e['last_message_at']) ??
        _parseDate(e['created_at']) ??
        DateTime.now();
    out.add(
      ConversationPreview(
        id: '$id',
        peer: MarketplaceUser(
          id: '$oid',
          name: (other['full_name'] as String?)?.trim().isNotEmpty == true
              ? (other['full_name'] as String).trim()
              : 'User',
          avatarUrl:
              (other['profile_image_url'] as String?)?.trim() ?? '',
          city: (other['city'] as String?)?.trim() ?? '',
        ),
        lastMessage: preview,
        time: at,
        unreadCount: 0,
      ),
    );
  }
  return out;
}

DateTime? _parseDate(Object? v) {
  if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
  return null;
}
