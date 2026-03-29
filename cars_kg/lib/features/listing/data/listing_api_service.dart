import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';

class ListingApiException implements Exception {
  ListingApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ListingApiService {
  ListingApiService(this._client);

  final ApiClient _client;

  String _errorFromDio(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) {
      return data['error'] as String;
    }
    return e.message ?? 'Request failed';
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    try {
      final r = await _client.get<dynamic>('/categories');
      final data = r.data;
      if (data is! List) {
        return [];
      }
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> createListing(Map<String, dynamic> body) async {
    try {
      final r = await _client.postJson('/listings', data: body);
      final data = r.data;
      if (data == null) {
        throw ListingApiException('Empty response');
      }
      return data;
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }

  Future<List<Map<String, dynamic>>> fetchMyListings() async {
    try {
      final r = await _client.get<dynamic>('/listings/me');
      final data = r.data;
      if (data is! List) {
        return [];
      }
      return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> getListing(int id) async {
    try {
      final r = await _client.get<Map<String, dynamic>>('/listings/$id');
      final data = r.data;
      if (data == null) {
        throw ListingApiException('Empty response');
      }
      return data;
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }

  Future<Map<String, dynamic>> updateListing(
    int id,
    Map<String, dynamic> patch,
  ) async {
    try {
      final r = await _client.patchJson('/listings/$id', data: patch);
      final data = r.data;
      if (data == null) {
        throw ListingApiException('Empty response');
      }
      return data;
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }

  Future<void> uploadListingImage(int listingId, XFile file) async {
    try {
      final fd = FormData.fromMap(<String, dynamic>{
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.name,
        ),
      });
      await _client.postMultipart('/listings/$listingId/media', data: fd);
    } on DioException catch (e) {
      throw ListingApiException(_errorFromDio(e), statusCode: e.response?.statusCode);
    }
  }
}
