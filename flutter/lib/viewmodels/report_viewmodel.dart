// lib/viewmodels/report_viewmodel.dart

import 'package:flutter/foundation.dart';
import '../models/dtos/report_dto.dart';
import '../services/report_service.dart';

class ReportViewModel extends ChangeNotifier {
  final ReportService _service;
  ReportViewModel([ReportService? service]) : _service = service ?? ReportService();

  // ── Filters ──
  String _reportType = ReportType.assets;
  DateTime? _startDate;
  DateTime? _endDate;

  // ── Preview state ──
  ReportPreview? _preview;
  bool _isGenerating = false;
  String? _error;

  // ── Export state ──
  bool _isExporting = false;
  String? _lastExportedPath;
  String? _exportError;

  // ── Getters ──
  String get reportType => _reportType;
  DateTime? get startDate => _startDate;
  DateTime? get endDate => _endDate;

  ReportPreview? get preview => _preview;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasPreview => _preview != null;

  bool get isExporting => _isExporting;
  String? get lastExportedPath => _lastExportedPath;
  String? get exportError => _exportError;

  // ── Setters ──

  void setReportType(String value) {
    _reportType = value;
    _preview = null;
    notifyListeners();
  }

  void setStartDate(DateTime? value) {
    _startDate = value;
    notifyListeners();
  }

  void setEndDate(DateTime? value) {
    _endDate = value;
    notifyListeners();
  }

  void clearFilters() {
    _startDate = null;
    _endDate = null;
    _preview = null;
    notifyListeners();
  }

  void clearExportState() {
    _lastExportedPath = null;
    _exportError = null;
    notifyListeners();
  }

  // ── Actions ──

  Future<void> generate() async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _preview = await _service.preview(
        reportType: _reportType,
        startDate: _startDate,
        endDate: _endDate,
      );
      _error = null;
    } catch (e) {
      _error = e.toString();
      _preview = null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  Future<String?> exportCsv() async {
    return _runExport(() => _service.exportCsv(
          reportType: _reportType,
          startDate: _startDate,
          endDate: _endDate,
        ));
  }

  Future<String?> exportExcel() async {
    return _runExport(() => _service.exportExcel(
          reportType: _reportType,
          startDate: _startDate,
          endDate: _endDate,
        ));
  }

  Future<String?> _runExport(Future<String> Function() action) async {
    _isExporting = true;
    _exportError = null;
    _lastExportedPath = null;
    notifyListeners();

    try {
      final path = await action();
      _lastExportedPath = path;
      _isExporting = false;
      notifyListeners();
      return path;
    } catch (e) {
      _exportError = e.toString();
      _isExporting = false;
      notifyListeners();
      return null;
    }
  }
}