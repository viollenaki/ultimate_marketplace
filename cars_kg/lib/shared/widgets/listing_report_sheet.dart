import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/listing/data/listing_api_service.dart';
import '../../features/listing/presentation/providers/listing_api_providers.dart';
import 'app_snackbar.dart';

/// Backend `ListingReportCreate.reason_code` values.
const kListingReportReasons = <String, String>{
  'spam': 'Spam or misleading',
  'scam': 'Scam or fraud',
  'misleading_info': 'Wrong or misleading info',
  'duplicate': 'Duplicate listing',
  'offensive': 'Offensive content',
  'other': 'Other',
};

Future<void> showListingReportSheet(
  BuildContext context, {
  required int listingId,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Consumer(
          builder: (context, ref, _) {
            return _ListingReportForm(listingId: listingId);
          },
        ),
      );
    },
  );
}

class _ListingReportForm extends ConsumerStatefulWidget {
  const _ListingReportForm({required this.listingId});

  final int listingId;

  @override
  ConsumerState<_ListingReportForm> createState() => _ListingReportFormState();
}

class _ListingReportFormState extends ConsumerState<_ListingReportForm> {
  String _reason = kListingReportReasons.keys.first;
  final _details = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _details.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    final api = ref.read(listingApiServiceProvider);
    try {
      await api.reportListing(
        widget.listingId,
        reasonCode: _reason,
        reasonDetails: _details.text.trim().isEmpty ? null : _details.text,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      showNotReadySnackBar(context, 'Thanks — your report was sent.');
    } on ListingApiException catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, e.message);
      }
    } on DioException catch (e) {
      if (mounted) {
        showNotReadySnackBar(context, e.message ?? 'Request failed');
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Report listing',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tell us what is wrong. Moderators review every report.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Reason',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final e in kListingReportReasons.entries)
                  ChoiceChip(
                    label: Text(e.value),
                    selected: _reason == e.key,
                    onSelected: _submitting
                        ? null
                        : (_) => setState(() => _reason = e.key),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _details,
              enabled: !_submitting,
              maxLines: 3,
              maxLength: 2000,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Submit report'),
            ),
          ],
        ),
      ),
    );
  }
}
