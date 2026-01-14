import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_models.dart';

class ReportService extends ChangeNotifier {
  String? _syncFolderPath;
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String? _error;

  String? get syncFolderPath => _syncFolderPath;
  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasSyncFolder => _syncFolderPath != null;

  ReportService() {
    _loadSavedPath();
  }

  Future<void> _loadSavedPath() async {
    final prefs = await SharedPreferences.getInstance();
    _syncFolderPath = prefs.getString('sync_folder_path');
    if (_syncFolderPath != null) {
      await loadPharmacies();
    }
    notifyListeners();
  }

  Future<void> _savePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_folder_path', path);
  }

  Future<void> pickSyncFolder() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        _syncFolderPath = selectedDirectory;
        await _savePath(selectedDirectory);
        await loadPharmacies();
      }
    } catch (e) {
      _error = 'خطأ في اختيار المجلد: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadPharmacies() async {
    if (_syncFolderPath == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final syncDir = Directory(_syncFolderPath!);
      if (!await syncDir.exists()) {
        _error = 'مجلد Sync غير موجود';
        _isLoading = false;
        notifyListeners();
        return;
      }

      _pharmacies = [];

      // البحث عن مجلدات الصيدليات (1, 2, 3, ...)
      await for (final entity in syncDir.list()) {
        if (entity is Directory) {
          final folderName = entity.path.split(Platform.pathSeparator).last;
          
          // تحقق من وجود MobileReports/reports.json
          final reportsFile = File('${entity.path}${Platform.pathSeparator}MobileReports${Platform.pathSeparator}reports.json');
          
          if (await reportsFile.exists()) {
            try {
              final content = await reportsFile.readAsString();
              final json = jsonDecode(content);
              final reports = PharmacyReports.fromJson(json);
              
              _pharmacies.add(Pharmacy(
                id: folderName,
                name: reports.meta.pharmacyName.isNotEmpty 
                    ? reports.meta.pharmacyName 
                    : 'صيدلية $folderName',
                folderPath: entity.path,
                reports: reports,
              ));
            } catch (e) {
              // تجاهل الملفات غير الصالحة
              debugPrint('Error loading pharmacy $folderName: $e');
            }
          }
        }
      }

      // ترتيب حسب رقم الصيدلية
      _pharmacies.sort((a, b) {
        final aNum = int.tryParse(a.id) ?? 999;
        final bNum = int.tryParse(b.id) ?? 999;
        return aNum.compareTo(bNum);
      });

      if (_pharmacies.isEmpty) {
        _error = 'لم يتم العثور على أي صيدليات';
      }
    } catch (e) {
      _error = 'خطأ في تحميل البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    await loadPharmacies();
  }

  void clearFolder() {
    _syncFolderPath = null;
    _pharmacies = [];
    _error = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('sync_folder_path');
    });
    notifyListeners();
  }

  // البحث في جميع الصيدليات
  List<MedicineWithPharmacy> searchAllPharmacies(String query) {
    if (query.isEmpty) return [];

    final results = <MedicineWithPharmacy>[];
    final queryLower = query.toLowerCase();

    for (final pharmacy in _pharmacies) {
      if (pharmacy.reports == null) continue;

      for (final medicine in pharmacy.reports!.inventoryList.data) {
        if (medicine.tradeNameAr.toLowerCase().contains(queryLower) ||
            medicine.tradeName.toLowerCase().contains(queryLower) ||
            medicine.genericName.toLowerCase().contains(queryLower)) {
          results.add(MedicineWithPharmacy(
            medicine: medicine,
            pharmacy: pharmacy,
          ));
        }
      }
    }

    return results;
  }

  // إحصائيات مجمعة لصنف معين من جميع الصيدليات
  MedicineAggregate? getAggregatedMedicine(int medicineId) {
    int totalStock = 0;
    double totalAvgConsumption = 0;
    int pharmacyCount = 0;
    String name = '';
    String nameAr = '';
    String genericName = '';

    for (final pharmacy in _pharmacies) {
      if (pharmacy.reports == null) continue;

      for (final medicine in pharmacy.reports!.inventoryList.data) {
        if (medicine.medicineId == medicineId) {
          totalStock += medicine.stock;
          totalAvgConsumption += medicine.avgConsumption;
          pharmacyCount++;
          if (name.isEmpty) {
            name = medicine.tradeName;
            nameAr = medicine.tradeNameAr;
            genericName = medicine.genericName;
          }
        }
      }
    }

    if (pharmacyCount == 0) return null;

    return MedicineAggregate(
      medicineId: medicineId,
      tradeName: name,
      tradeNameAr: nameAr,
      genericName: genericName,
      totalStock: totalStock,
      avgConsumption: totalAvgConsumption / pharmacyCount,
      pharmacyCount: pharmacyCount,
    );
  }
}

class MedicineWithPharmacy {
  final Medicine medicine;
  final Pharmacy pharmacy;

  MedicineWithPharmacy({
    required this.medicine,
    required this.pharmacy,
  });
}

class MedicineAggregate {
  final int medicineId;
  final String tradeName;
  final String tradeNameAr;
  final String genericName;
  final int totalStock;
  final double avgConsumption;
  final int pharmacyCount;

  MedicineAggregate({
    required this.medicineId,
    required this.tradeName,
    required this.tradeNameAr,
    required this.genericName,
    required this.totalStock,
    required this.avgConsumption,
    required this.pharmacyCount,
  });
}
