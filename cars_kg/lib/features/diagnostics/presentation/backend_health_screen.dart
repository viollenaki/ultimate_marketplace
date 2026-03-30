import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/network/api_providers.dart';
import '../../../core/theme/app_palette.dart';

class BackendHealthScreen extends ConsumerStatefulWidget {
  const BackendHealthScreen({super.key});

  @override
  ConsumerState<BackendHealthScreen> createState() =>
      _BackendHealthScreenState();
}

class _BackendHealthScreenState extends ConsumerState<BackendHealthScreen> {
  bool _loading = false;
  String? _result;
  String? _error;

  Future<void> _ping(
    String pathOrAbsoluteUrl, {
    required String label,
  }) async {
    setState(() {
      _loading = true;
      _result = null;
      _error = null;
    });
    final dio = ref.read(apiClientProvider).dio;
    final uri = pathOrAbsoluteUrl.startsWith('http://') ||
            pathOrAbsoluteUrl.startsWith('https://')
        ? pathOrAbsoluteUrl
        : pathOrAbsoluteUrl.startsWith('/')
            ? pathOrAbsoluteUrl
            : '/$pathOrAbsoluteUrl';
    try {
      final response = await dio.get<String>(
        uri,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (code) => code != null && code < 500,
        ),
      );
      final body = response.data?.trim();
      final summary =
          '$label\nHTTP ${response.statusCode}\n${body == null || body.isEmpty ? '(empty body)' : body}';
      setState(() {
        _loading = false;
        _result = summary;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = e.message ?? e.toString();
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lanOverride = Env.lanHealthCheckUrl != Env.backendHealthUrl;

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Server origin (BACKEND_URL)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            Env.backendOrigin,
            style: const TextStyle(
              color: AppPalette.textPrimary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'API base (used by ApiClient)',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          SelectableText(
            Env.apiBaseUrl,
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            'Relative paths are resolved under this URL (e.g. /health → …/api/v1/health).',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppPalette.textSecondary,
                ),
          ),
          if (lanOverride) ...[
            const SizedBox(height: 20),
            Text(
              'LAN_HEALTH_CHECK_URL override',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              Env.lanHealthCheckUrl,
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _loading
                ? null
                : () => _ping('/health', label: 'GET ${Env.backendHealthUrl}'),
            icon: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.dns_outlined),
            label: Text(_loading ? 'Checking…' : 'GET /health (ApiClient)'),
          ),
          if (lanOverride) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading
                  ? null
                  : () => _ping(
                        Env.lanHealthCheckUrl,
                        label: 'GET ${Env.lanHealthCheckUrl}',
                      ),
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('Ping LAN_HEALTH_CHECK_URL'),
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 24),
            Text(
              'Result',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _result!,
              style: const TextStyle(
                color: AppPalette.success,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 24),
            Text(
              'Error',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppPalette.error,
                  ),
            ),
            const SizedBox(height: 8),
            SelectableText(
              _error!,
              style: const TextStyle(color: AppPalette.error, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}
