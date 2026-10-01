// lib/api/department_api.dart

import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/dtos/department_dto.dart';

class DepartmentApi {
  final Dio _dio;
  DepartmentApi([Dio? dio]) : _dio = dio ?? ApiClient.dio;

  Future<List<DepartmentDto>> getAll() async {
    final response = await _dio.get('/api/departments');
    final code = response.statusCode ?? 0;

    if (code == 200) {
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(DepartmentDto.fromJson)
            .toList();
      }
      return const [];
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to load departments.',
      statusCode: code,
    );
  }

  Future<void> create(DepartmentRequest request) async {
    final response = await _dio.post(
      '/api/departments',
      data: request.toJson(),
    );
    final code = response.statusCode ?? 0;

    if (code == 201 || code == 200) return;

    throw ApiException(
      _extractError(response) ?? 'Unable to create the department.',
      statusCode: code,
    );
  }

  Future<void> update(String id, DepartmentRequest request) async {
    final response = await _dio.patch(
      '/api/departments/$id',
      data: request.toJson(),
    );
    final code = response.statusCode ?? 0;

    if (code == 200 || code == 204) return;

    throw ApiException(
      _extractError(response) ?? 'Unable to update the department.',
      statusCode: code,
    );
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete('/api/departments/$id');
    final code = response.statusCode ?? 0;

    if (code == 204 || code == 200) return;

    throw ApiException(
      _extractError(response) ?? 'Unable to delete the department.',
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