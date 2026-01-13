import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_models.dart';

class ReportService extends ChangeNotifier {
  AllReports? _reports;
  String? _reportsPath;
  bool _isLoading = false;
  String? _error;
  DateTime? _lastUpdate;

  AllReports? get reports => _reports;
  String? get reportsPath => _reportsPath;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime? get lastUpdate => _lastUpdate;
  bool get hasData => _reports != null;

  ReportService() {
    _loadSavedPath();
  }

  // تحميل المسار المحفوظ
  Future<void> _loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    _reportsPath = prefs.getString('reports_path');
    if (_reportsPath != null) {
      await loadReports();
    }
  }

  // حفظ المسار
  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('reports_path', path);
    _reportsPath = path;
  }

  // اختيار ملف التقارير
  Future<bool> pickReportsFile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'اختر ملف reports.json',
      );

      if (result != null && result.files.single.path != null) {
        final path = result.files.single.path!;
        await _savePath(path);
        return await loadReports();
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'خطأ في اختيار الملف: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // اختيار مجلد التقارير
  Future<bool> pickReportsFolder() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'اختر مجلد MobileReports',
      );

      if (selectedDirectory != null) {
        final reportsFile = File('$selectedDirectory/reports.json');
        if (await reportsFile.exists()) {
          await _savePath(reportsFile.path);
          return await loadReports();
        } else {
          _error = 'لم يتم العثور على ملف reports.json في المجلد المحدد';
          _isLoading = false;
          notifyListeners();
          return false;
        }
      }

      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = 'خطأ في اختيار المجلد: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تحميل التقارير من الملف
  Future<bool> loadReports() async {
    if (_reportsPath == null) {
      _error = 'لم يتم تحديد مسار الملف';
      notifyListeners();
      return false;
    }

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final file = File(_reportsPath!);
      if (!await file.exists()) {
        _error = 'الملف غير موجود';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final content = await file.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;
      _reports = AllReports.fromJson(json);
      _lastUpdate = DateTime.now();
      _error = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'خطأ في قراءة الملف: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // تحديث التقارير
  Future<bool> refresh() async {
    return await loadReports();
  }

  // مسح البيانات
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reports_path');
    _reports = null;
    _reportsPath = null;
    _lastUpdate = null;
    _error = null;
    notifyListeners();
  }

  // البحث في الأصناف
  List<Medicine> searchMedicines(String query, List<Medicine> medicines) {
    if (query.isEmpty) return medicines;
    final lowerQuery = query.toLowerCase();
    return medicines.where((m) {
      return m.displayName.toLowerCase().contains(lowerQuery) ||
          m.tradeName.toLowerCase().contains(lowerQuery) ||
          m.genericName.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  // تجميع حسب الموقع
  Map<String, List<Medicine>> groupByLocation(List<Medicine> medicines) {
    final Map<String, List<Medicine>> grouped = {};
    for (var med in medicines) {
      final location = med.location.isEmpty ? 'غير محدد' : med.location;
      grouped.putIfAbsent(location, () => []);
      grouped[location]!.add(med);
    }
    return grouped;
  }
}
