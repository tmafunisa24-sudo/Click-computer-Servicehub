// lib/services/report_service.dart

import '../api/report_api.dart';
import '../models/dtos/report_dto.dart';

class ReportService {
  final ReportApi _api;
  ReportService([ReportApi? api]) : _api = api ?? ReportApi();

  Future<ReportPreview> preview({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.preview(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<String> exportCsv({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.exportCsv(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<String> exportExcel({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _api.exportExcel(
      reportType: reportType,
      startDate: startDate,
      endDate: endDate,
    );
  }
}