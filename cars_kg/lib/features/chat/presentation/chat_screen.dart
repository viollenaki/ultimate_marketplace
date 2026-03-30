import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';
import '../../auth/presentation/providers/auth_providers.dart';
import 'api_conversation_chat_notifier.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final useMock = ref.watch(mockModeProvider);

    if (useMock) {
      return _buildMockChat(context);
    }
    return _buildApiChat(context);
  }

  Widget _buildMockChat(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final peer = _findMockPeer(widget.conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage(
                peer?.avatarUrl ?? currentUser.avatarUrl,
              ),
            ),
            const SizedBox(width: 10),
            Text(peer?.name ?? 'Chat'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final message = messages[index];
                final mine = message.senderId == currentUserId;
                return _bubble(context, message, mine);
              },
            ),
          ),
          _mockComposer(context),
        ],
      ),
    );
  }

  Widget _buildApiChat(BuildContext context) {
    final chat = ref.watch(apiConversationChatProvider(widget.conversationId));
    final auth = ref.watch(authControllerProvider);
    final peer = _apiPeer(ref, widget.conversationId);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: peer?.avatarUrl.isNotEmpty == true
                  ? NetworkImage(peer!.avatarUrl)
                  : null,
              child: peer?.avatarUrl.isNotEmpty != true
                  ? Text(
                      (peer?.name ?? 'C').isNotEmpty
                          ? peer!.name[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(peer?.name ?? 'Chat'),
                  if (!chat.socketConnected && !chat.isLoadingInitial)
                    Text(
                      'Reconnecting…',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppPalette.textSecondary,
                          ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (chat.bannerError != null)
            Material(
              color: AppPalette.error.withValues(alpha: 0.12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        chat.bannerError!,
                        style: TextStyle(
                          color: AppPalette.error,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: chat.isLoadingInitial
                ? const Center(child: CircularProgressIndicator())
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n is ScrollEndNotification &&
                          n.metrics.pixels <= 64 &&
                          chat.nextBeforeId != null &&
                          !chat.isLoadingOlder) {
                        ref
                            .read(
                              apiConversationChatProvider(widget.conversationId)
                                  .notifier,
                            )
                            .loadOlder();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                      itemCount: chat.messages.length,
                      itemBuilder: (context, index) {
                        final message = chat.messages[index];
                        final mine = auth.userId != null &&
                            message.senderId == '${auth.userId}';
                        return _bubble(context, message, mine);
                      },
                    ),
                  ),
          ),
          _apiComposer(context, auth),
        ],
      ),
    );
  }

  Widget _bubble(BuildContext context, ChatMessage message, bool mine) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: mine ? AppPalette.primary : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.attachmentLabel != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  message.attachmentLabel!,
                  style: TextStyle(
                    color: mine
                        ? Colors.white.withValues(alpha: 0.95)
                        : AppPalette.secondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                color: mine ? Colors.white : AppPalette.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mockComposer(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => showNotReadySnackBar(
                context,
                'Attachment picker is next',
              ),
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref
                    .read(
                      chatMessagesProvider(widget.conversationId).notifier,
                    )
                    .sendMessage(_controller.text);
                _controller.clear();
              },
              icon: const Icon(
                Icons.send_rounded,
                color: AppPalette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _apiComposer(BuildContext context, AuthState auth) {
    final canSend =
        auth.isAuthenticated && auth.jwt != null && auth.jwt!.isNotEmpty;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 12),
        child: Row(
          children: [
            IconButton(
              onPressed: () => showNotReadySnackBar(
                context,
                'Attachment picker is next',
              ),
              icon: const Icon(Icons.attach_file),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: canSend,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Write a message...',
                ),
              ),
            ),
            IconButton(
              onPressed: !canSend
                  ? null
                  : () {
                      ref
                          .read(
                            apiConversationChatProvider(widget.conversationId)
                                .notifier,
                          )
                          .sendMessage(_controller.text);
                      _controller.clear();
                    },
              icon: const Icon(
                Icons.send_rounded,
                color: AppPalette.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  MarketplaceUser? _findMockPeer(String conversationId) {
    for (final conversation in mockConversations) {
      if (conversation.id == conversationId) {
        return conversation.peer;
      }
    }
    return null;
  }

  MarketplaceUser? _apiPeer(WidgetRef ref, String conversationId) {
    final async = ref.watch(conversationsProvider);
    return async.maybeWhen(
      data: (list) {
        for (final c in list) {
          if (c.id == conversationId) return c.peer;
        }
        return null;
      },
      orElse: () => null,
    );
  }
}
