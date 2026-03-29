import 'package:dio/dio.dart';

import '../config/env.dart';

/// HTTP client for the marketplace API. All paths are relative to [Env.apiBaseUrl]
/// (e.g. `/health`, `/auth/sessions`).
class ApiClient {
  ApiClient({Dio? dio}) : dio = dio ?? Dio(baseOptions());

  /// Share [BaseOptions] for unauthenticated and Bearer-authenticated clients.
  ApiClient.withDio(this.dio);

  final Dio dio;

  static BaseOptions baseOptions() {
    return BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 60),
      headers: const {
        'Accept': 'application/json',
      },
    );
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) {
    return dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
    );
  }

  Future<Response<Map<String, dynamic>>> postJson(
    String path, {
    required Map<String, dynamic> data,
  }) {
    return dio.post<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response<Map<String, dynamic>>> patchJson(
    String path, {
    required Map<String, dynamic> data,
  }) {
    return dio.patch<Map<String, dynamic>>(
      path,
      data: data,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
  }

  Future<Response<dynamic>> postMultipart(
    String path, {
    required FormData data,
  }) {
    return dio.post<dynamic>(
      path,
      data: data,
      options: Options(
        contentType: 'multipart/form-data',
        headers: {'Accept': 'application/json'},
      ),
    );
  }
}
