// lib/api/report_api.dart

import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../models/dtos/report_dto.dart';

class ReportApi {
  final Dio _dio;
  ReportApi([Dio? dio]) : _dio = dio ?? ApiClient.dio;

  /// GET /api/reports/preview?reportType=...
  Future<ReportPreview> preview({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{
      'reportType': reportType,
    };
    if (startDate != null) {
      params['startDate'] = _dateOnly(startDate);
    }
    if (endDate != null) {
      params['endDate'] = _dateOnly(endDate);
    }

    final response = await _dio.get(
      '/api/reports/preview',
      queryParameters: params,
    );

    final code = response.statusCode ?? 0;

    if (code == 200) {
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ReportPreview.fromJson(data);
      }
      throw ApiException('Invalid response.', statusCode: code);
    }

    throw ApiException(
      _extractError(response) ?? 'Unable to generate the report.',
      statusCode: code,
    );
  }

  /// GET /api/reports/export/csv — saves the file and returns its path.
  Future<String> exportCsv({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _download(
      endpoint: '/api/reports/export/csv',
      extension: 'csv',
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// GET /api/reports/export/excel — saves the file and returns its path.
  Future<String> exportExcel({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return _download(
      endpoint: '/api/reports/export/excel',
      extension: 'xlsx',
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  // ────────────────────────────────────────────────────────
  // Helpers
  // ────────────────────────────────────────────────────────

  static String _dateOnly(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Future<String> _download({
    required String endpoint,
    required String extension,
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{
      'reportType': reportType,
    };
    if (startDate != null) params['startDate'] = _dateOnly(startDate);
    if (endDate != null) params['endDate'] = _dateOnly(endDate);

    final response = await _dio.get<List<int>>(
      endpoint,
      queryParameters: params,
      options: Options(responseType: ResponseType.bytes),
    );

    final code = response.statusCode ?? 0;

    if (code != 200) {
      throw ApiException(
        'Unable to export the report (status $code).',
        statusCode: code,
      );
    }

    final bytes = Uint8List.fromList(response.data ?? const []);

    if (bytes.isEmpty) {
      throw ApiException('The exported file was empty.');
    }

    // Build a filename like "assets-report-2026-09-28.csv"
    final timestamp = _dateOnly(DateTime.now());
    final baseName = reportType.toLowerCase().replaceAll(' ', '-');
    final filename = '$baseName-report-$timestamp.$extension';

    // Get the target directory
    Directory? dir = await getDownloadsDirectory();
    dir ??= await getApplicationDocumentsDirectory();

    // Ensure a subfolder so files don't clutter the user's Downloads
    final appFolder = Directory('${dir.path}/ServiceHubReports');
    if (!await appFolder.exists()) {
      await appFolder.create(recursive: true);
    }

    final file = File('${appFolder.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);

    return file.path;
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