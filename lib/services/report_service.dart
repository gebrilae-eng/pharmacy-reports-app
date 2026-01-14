import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_models.dart';

class ReportService extends ChangeNotifier {
  // Folder ID من لينك Google Drive
  static const String _defaultSyncFolderId = '1RFz6EhJdkEVpqAoD7NsvXM_0bqB_dIR3';
  
  // Google API Key (للقراءة فقط من المجلدات العامة)
  static const String _apiKey = 'AIzaSyDummy'; // سنستخدم طريقة أخرى

  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;

  ReportService() {
    loadPharmacies();
  }

  Future<void> loadPharmacies() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pharmacies = [];

      // قراءة المجلدات الفرعية (1, 2, 3, ...)
      final foldersUrl = Uri.parse(
        'https://www.googleapis.com/drive/v3/files'
        '?q=%27$_defaultSyncFolderId%27+in+parents+and+mimeType%3D%27application%2Fvnd.google-apps.folder%27'
        '&key=$_apiKey'
        '&fields=files(id,name)'
      );

      // بما أن المجلد عام، نحاول القراءة مباشرة
      // لكن Google Drive API يحتاج API Key
      
      // الحل البديل: قراءة من ملف config ثابت
      await _loadFromConfig();

      _isInitialized = true;
    } catch (e) {
      _error = 'خطأ في تحميل البيانات: $e';
      debugPrint('Load error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromConfig() async {
    // سنقرأ الصيدليات من ملف JSON مخزن محلياً أو من URL ثابت
    // المستخدم يمكنه تحميل الملف يدوياً
    
    // محاولة قراءة البيانات المحفوظة
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString('pharmacies_data');
    
    if (savedData != null) {
      try {
        final List<dynamic> dataList = jsonDecode(savedData);
        _pharmacies = dataList.map((data) {
          return Pharmacy(
            id: data['id'],
            name: data['name'],
            folderPath: data['folderPath'] ?? '',
            reports: data['reports'] != null 
                ? PharmacyReports.fromJson(data['reports'])
                : null,
          );
        }).toList();
      } catch (e) {
        debugPrint('Error loading saved data: $e');
      }
    }
  }

  Future<void> loadFromFile(String jsonContent) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final data = jsonDecode(jsonContent);
      
      if (data is Map<String, dynamic>) {
        // ملف تقارير صيدلية واحدة
        final reports = PharmacyReports.fromJson(data);
        final pharmacyId = reports.meta.pharmacyId;
        
        // تحديث أو إضافة الصيدلية
        final existingIndex = _pharmacies.indexWhere((p) => p.id == pharmacyId);
        final pharmacy = Pharmacy(
          id: pharmacyId,
          name: reports.meta.pharmacyName.isNotEmpty 
              ? reports.meta.pharmacyName 
              : 'صيدلية $pharmacyId',
          folderPath: '',
          reports: reports,
        );
        
        if (existingIndex >= 0) {
          _pharmacies[existingIndex] = pharmacy;
        } else {
          _pharmacies.add(pharmacy);
        }
        
        // ترتيب
        _pharmacies.sort((a, b) {
          final aNum = int.tryParse(a.id) ?? 999;
          final bNum = int.tryParse(b.id) ?? 999;
          return aNum.compareTo(bNum);
        });
        
        // حفظ البيانات
        await _saveData();
      }

      _isInitialized = true;
    } catch (e) {
      _error = 'خطأ في قراءة الملف: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMultipleFiles(List<String> jsonContents) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      for (final content in jsonContents) {
        try {
          final data = jsonDecode(content);
          if (data is Map<String, dynamic>) {
            final reports = PharmacyReports.fromJson(data);
            final pharmacyId = reports.meta.pharmacyId;
            
            final existingIndex = _pharmacies.indexWhere((p) => p.id == pharmacyId);
            final pharmacy = Pharmacy(
              id: pharmacyId,
              name: reports.meta.pharmacyName.isNotEmpty 
                  ? reports.meta.pharmacyName 
                  : 'صيدلية $pharmacyId',
              folderPath: '',
              reports: reports,
            );
            
            if (existingIndex >= 0) {
              _pharmacies[existingIndex] = pharmacy;
            } else {
              _pharmacies.add(pharmacy);
            }
          }
        } catch (e) {
          debugPrint('Error parsing file: $e');
        }
      }

      _pharmacies.sort((a, b) {
        final aNum = int.tryParse(a.id) ?? 999;
        final bNum = int.tryParse(b.id) ?? 999;
        return aNum.compareTo(bNum);
      });

      await _saveData();
      _isInitialized = true;
    } catch (e) {
      _error = 'خطأ في قراءة الملفات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataList = _pharmacies.map((p) => {
      'id': p.id,
      'name': p.name,
      'folderPath': p.folderPath,
      'reports': p.reports != null ? _reportsToJson(p.reports!) : null,
    }).toList();
    await prefs.setString('pharmacies_data', jsonEncode(dataList));
  }

  Map<String, dynamic> _reportsToJson(PharmacyReports reports) {
    return {
      'meta': {
        'exported_at': reports.meta.exportedAt,
        'pharmacy_id': reports.meta.pharmacyId,
        'pharmacy_name': reports.meta.pharmacyName,
        'hospital_name': reports.meta.hospitalName,
        'directory_name': reports.meta.directoryName,
      },
      'daily_inventory': {
        'title': reports.dailyInventory.title,
        'date': reports.dailyInventory.date,
        'data': reports.dailyInventory.data.map((m) => _medicineToJson(m)).toList(),
      },
      'shortages': {
        'title': reports.shortages.title,
        'date': reports.shortages.date,
        'data': reports.shortages.data.map((m) => _medicineToJson(m)).toList(),
      },
      'inventory_list': {
        'title': reports.inventoryList.title,
        'date': reports.inventoryList.date,
        'data': reports.inventoryList.data.map((m) => _medicineToJson(m)).toList(),
      },
      'balance_list': {
        'title': reports.balanceList.title,
        'date': reports.balanceList.date,
        'data': reports.balanceList.data.map((m) => _medicineToJson(m)).toList(),
      },
    };
  }

  Map<String, dynamic> _medicineToJson(Medicine m) {
    return {
      'medicine_id': m.medicineId,
      'trade_name': m.tradeName,
      'trade_name_ar': m.tradeNameAr,
      'generic_name': m.genericName,
      'strength': m.strength,
      'form': m.form,
      'location': m.location,
      'current_stock': m.currentStock,
      'total_stock': m.totalStock,
      'total_dispensed': m.totalDispensed,
      'min_stock': m.minStock,
      'total_value': m.totalValue,
      'avg_consumption': m.avgConsumption,
      'nearest_expiry': m.nearestExpiry,
    };
  }

  Future<void> refresh() async {
    // إعادة تحميل من الملفات المحفوظة
    await loadPharmacies();
  }

  void clearData() {
    _pharmacies = [];
    _error = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('pharmacies_data');
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
}

class MedicineWithPharmacy {
  final Medicine medicine;
  final Pharmacy pharmacy;

  MedicineWithPharmacy({
    required this.medicine,
    required this.pharmacy,
  });
}
