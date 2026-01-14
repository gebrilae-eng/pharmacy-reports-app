import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/report_models.dart';

class ReportService extends ChangeNotifier {
  static const String _clientId = '81937439657-hcqlu6khorhoct7jngr2fes0v0g6811c.apps.googleusercontent.com';
  
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['https://www.googleapis.com/auth/drive.readonly'],
    serverClientId: _clientId,
  );

  GoogleSignInAccount? _currentUser;
  String? _syncFolderId;
  List<Pharmacy> _pharmacies = [];
  bool _isLoading = false;
  String? _error;
  bool _isSignedIn = false;

  GoogleSignInAccount? get currentUser => _currentUser;
  String? get syncFolderId => _syncFolderId;
  List<Pharmacy> get pharmacies => _pharmacies;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isSignedIn => _isSignedIn;
  bool get hasSyncFolder => _syncFolderId != null;

  ReportService() {
    _init();
  }

  Future<void> _init() async {
    _googleSignIn.onCurrentUserChanged.listen((account) {
      _currentUser = account;
      _isSignedIn = account != null;
      notifyListeners();
    });

    // محاولة تسجيل دخول صامت
    try {
      await _googleSignIn.signInSilently();
      if (_isSignedIn) {
        await _loadSavedFolderId();
      }
    } catch (e) {
      debugPrint('Silent sign in failed: $e');
    }
    notifyListeners();
  }

  Future<void> _loadSavedFolderId() async {
    final prefs = await SharedPreferences.getInstance();
    _syncFolderId = prefs.getString('sync_folder_id');
    if (_syncFolderId != null) {
      await loadPharmacies();
    }
  }

  Future<void> _saveFolderId(String folderId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('sync_folder_id', folderId);
  }

  Future<void> signIn() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      await _googleSignIn.signIn();
      
      if (_isSignedIn) {
        await _loadSavedFolderId();
      }
    } catch (e) {
      _error = 'فشل تسجيل الدخول: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _syncFolderId = null;
    _pharmacies = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sync_folder_id');
    notifyListeners();
  }

  Future<Map<String, String>?> _getAuthHeaders() async {
    final auth = await _currentUser?.authentication;
    if (auth == null) return null;
    return {
      'Authorization': 'Bearer ${auth.accessToken}',
      'Accept': 'application/json',
    };
  }

  // البحث عن مجلد Sync في Google Drive
  Future<List<DriveFolder>> searchSyncFolders() async {
    final headers = await _getAuthHeaders();
    if (headers == null) return [];

    try {
      // البحث عن مجلدات باسم Sync
      final query = "name = 'Sync' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&fields=files(id,name,parents)'
      );

      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final files = data['files'] as List;
        return files.map((f) => DriveFolder(
          id: f['id'],
          name: f['name'],
        )).toList();
      }
    } catch (e) {
      debugPrint('Error searching folders: $e');
    }
    return [];
  }

  Future<void> selectSyncFolder(String folderId) async {
    _syncFolderId = folderId;
    await _saveFolderId(folderId);
    await loadPharmacies();
  }

  Future<void> loadPharmacies() async {
    if (_syncFolderId == null || !_isSignedIn) return;

    final headers = await _getAuthHeaders();
    if (headers == null) return;

    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      _pharmacies = [];

      // البحث عن المجلدات الفرعية (1, 2, 3, ...)
      final query = "'$_syncFolderId' in parents and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
      final url = Uri.parse(
        'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(query)}&fields=files(id,name)'
      );

      final response = await http.get(url, headers: headers);
      
      if (response.statusCode != 200) {
        _error = 'فشل في قراءة المجلدات';
        return;
      }

      final data = jsonDecode(response.body);
      final folders = data['files'] as List;

      for (final folder in folders) {
        final folderId = folder['id'];
        final folderName = folder['name'];

        // البحث عن مجلد MobileReports
        final mobileReportsQuery = "'$folderId' in parents and name = 'MobileReports' and mimeType = 'application/vnd.google-apps.folder' and trashed = false";
        final mrUrl = Uri.parse(
          'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(mobileReportsQuery)}&fields=files(id)'
        );
        final mrResponse = await http.get(mrUrl, headers: headers);

        if (mrResponse.statusCode == 200) {
          final mrData = jsonDecode(mrResponse.body);
          final mrFolders = mrData['files'] as List;

          if (mrFolders.isNotEmpty) {
            final mrFolderId = mrFolders.first['id'];

            // البحث عن reports.json
            final jsonQuery = "'$mrFolderId' in parents and name = 'reports.json' and trashed = false";
            final jsonUrl = Uri.parse(
              'https://www.googleapis.com/drive/v3/files?q=${Uri.encodeComponent(jsonQuery)}&fields=files(id)'
            );
            final jsonResponse = await http.get(jsonUrl, headers: headers);

            if (jsonResponse.statusCode == 200) {
              final jsonData = jsonDecode(jsonResponse.body);
              final jsonFiles = jsonData['files'] as List;

              if (jsonFiles.isNotEmpty) {
                final fileId = jsonFiles.first['id'];
                
                // تحميل محتوى الملف
                final contentUrl = Uri.parse(
                  'https://www.googleapis.com/drive/v3/files/$fileId?alt=media'
                );
                final contentResponse = await http.get(contentUrl, headers: headers);

                if (contentResponse.statusCode == 200) {
                  try {
                    final reports = PharmacyReports.fromJson(
                      jsonDecode(utf8.decode(contentResponse.bodyBytes))
                    );
                    
                    _pharmacies.add(Pharmacy(
                      id: folderName,
                      name: reports.meta.pharmacyName.isNotEmpty 
                          ? reports.meta.pharmacyName 
                          : 'صيدلية $folderName',
                      folderPath: folderId,
                      reports: reports,
                    ));
                  } catch (e) {
                    debugPrint('Error parsing reports for $folderName: $e');
                  }
                }
              }
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
        _error = 'لم يتم العثور على أي صيدليات في مجلد Sync';
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
    _syncFolderId = null;
    _pharmacies = [];
    _error = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('sync_folder_id');
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

class DriveFolder {
  final String id;
  final String name;

  DriveFolder({required this.id, required this.name});
}

class MedicineWithPharmacy {
  final Medicine medicine;
  final Pharmacy pharmacy;

  MedicineWithPharmacy({
    required this.medicine,
    required this.pharmacy,
  });
}
