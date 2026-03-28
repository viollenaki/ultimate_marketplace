import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_palette.dart';
import '../../../data/mock/mock_providers.dart';

class PromotionsPaymentsScreen extends ConsumerWidget {
  const PromotionsPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(promotionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Promotions & Payments')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppPalette.primary.withValues(alpha: 0.12),
                child: const Icon(Icons.trending_up, color: AppPalette.primary),
              ),
              title: Text(
                item.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(DateFormat.yMMMd().format(item.date)),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${item.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    item.status,
                    style: TextStyle(
                      color: item.status == 'Completed'
                          ? AppPalette.success
                          : AppPalette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
