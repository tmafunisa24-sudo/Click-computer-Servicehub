// lib/api/user_api.dart

import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/profile.dart';

class UserApi {
  final Dio _dio;
  UserApi([Dio? dio]) : _dio = dio ?? ApiClient.dio;

  /// GET /api/users — admin only
  Future<List<Profile>> getAll() async {
    final response = await _dio.get('/api/users');
    final code = response.statusCode ?? 0;

    if (code == 200) {
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(Profile.fromJson)
            .toList();
      }
      return const [];
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to load users.',
      statusCode: code,
    );
  }

  /// PATCH /api/users/{id} — admin only
  /// Only role and status are editable.
  Future<Profile> updateUser({
    required String userId,
    String? role,
    String? status,
  }) async {
    final payload = <String, dynamic>{};
    if (role != null && role.isNotEmpty) payload['role'] = role;
    if (status != null && status.isNotEmpty) payload['status'] = status;

    final response = await _dio.patch(
      '/api/users/$userId',
      data: payload,
    );

    final code = response.statusCode ?? 0;

    if (code == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return Profile.fromJson(data);
      }
      throw ApiException('Invalid response.', statusCode: code);
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to update the user.',
      statusCode: code,
    );
  }

  String? _extractError(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) {
      if (data['error'] is String) return data['error'] as String;
      if (data['detail'] is String) return data['detail'] as String;
    }
    return null;
  }
}