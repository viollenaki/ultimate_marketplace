import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_data.dart';
import '../../../data/mock/mock_models.dart';
import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/app_snackbar.dart';

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
    final messages = ref.watch(chatMessagesProvider(widget.conversationId));
    final peer = _findPeer(widget.conversationId);

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
                return Align(
                  alignment: mine
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
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
              },
            ),
          ),
          SafeArea(
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
                            chatMessagesProvider(
                              widget.conversationId,
                            ).notifier,
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
          ),
        ],
      ),
    );
  }

  MarketplaceUser? _findPeer(String conversationId) {
    for (final conversation in mockConversations) {
      if (conversation.id == conversationId) {
        return conversation.peer;
      }
    }
    return null;
  }
}
