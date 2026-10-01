// lib/api/maintenance_api.dart

import 'package:dio/dio.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/dtos/maintenance_dto.dart';

class MaintenanceApi {
  final Dio _dio;
  MaintenanceApi([Dio? dio]) : _dio = dio ?? ApiClient.dio;

  Future<List<MaintenanceRecord>> getAll() async {
    final response = await _dio.get('/api/maintenance');
    final code = response.statusCode ?? 0;

    if (code == 200) {
      final data = response.data;
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(MaintenanceRecord.fromJson)
            .toList();
      }
      return const [];
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to load maintenance.',
      statusCode: code,
    );
  }

  Future<MaintenanceRecord> getById(String id) async {
    final response = await _dio.get('/api/maintenance/$id');
    final code = response.statusCode ?? 0;

    if (code == 200) {
      return MaintenanceRecord.fromJson(response.data as Map<String, dynamic>);
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to load the record.',
      statusCode: code,
    );
  }

  Future<String> create(MaintenanceRequest request) async {
    final response = await _dio.post('/api/maintenance', data: request.toJson());
    final code = response.statusCode ?? 0;

    if (code == 201 || code == 200) {
      final data = response.data;
      if (data is Map<String, dynamic> && data['id'] is String) {
        return data['id'] as String;
      }
      return '';
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to create the record.',
      statusCode: code,
    );
  }

  Future<void> update(String id, MaintenanceRequest request) async {
    final response = await _dio.patch(
      '/api/maintenance/$id',
      data: request.toJson(),
    );
    final code = response.statusCode ?? 0;

    if (code == 200) return;

    throw ApiException(
      _extractError(response) ?? 'Unable to update the record.',
      statusCode: code,
    );
  }

  Future<void> delete(String id) async {
    final response = await _dio.delete('/api/maintenance/$id');
    final code = response.statusCode ?? 0;
    if (code == 204 || code == 200) return;

    throw ApiException(
      _extractError(response) ?? 'Unable to delete the record.',
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