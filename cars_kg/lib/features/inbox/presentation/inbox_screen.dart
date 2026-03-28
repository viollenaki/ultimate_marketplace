import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../data/mock/mock_providers.dart';
import '../../../shared/widgets/marketplace_bottom_nav.dart';
import '../../../shared/widgets/state_views.dart';

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversations = ref.watch(conversationsProvider);
    final mode = ref.watch(inboxStateProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Inbox'),
        actions: [
          PopupMenuButton<DemoLoadState>(
            initialValue: mode,
            onSelected: (value) =>
                ref.read(inboxStateProvider.notifier).state = value,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: DemoLoadState.data,
                child: Text('Data state'),
              ),
              PopupMenuItem(
                value: DemoLoadState.empty,
                child: Text('Empty state'),
              ),
              PopupMenuItem(
                value: DemoLoadState.error,
                child: Text('Error state'),
              ),
            ],
          ),
        ],
      ),
      body: conversations.when(
        loading: () =>
            const LoadingStateView(label: 'Loading conversations...'),
        error: (error, stackTrace) => ErrorStateView(
          message: error.toString(),
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const EmptyStateView(
              title: 'No conversations yet',
              subtitle: 'When buyers write to you, chats will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                onTap: () => context.push('/chat/${item.id}'),
                tileColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: CircleAvatar(
                  backgroundImage: NetworkImage(item.peer.avatarUrl),
                ),
                title: Text(
                  item.peer.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  item.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(DateFormat.Hm().format(item.time)),
                    if (item.unreadCount > 0)
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          item.unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: MarketplaceBottomNav(
        currentPath: GoRouterState.of(context).uri.path,
      ),
    );
  }
}
