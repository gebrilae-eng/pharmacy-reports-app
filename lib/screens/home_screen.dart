import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../services/report_service.dart';
import 'all_pharmacies_screen.dart';
import 'pharmacy_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('تقارير الصيدلية'),
          actions: [
            Consumer<ReportService>(
              builder: (context, service, _) {
                return PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    if (value == 'add') {
                      await _pickFiles(context, service);
                    } else if (value == 'refresh') {
                      service.refresh();
                    } else if (value == 'clear') {
                      _showClearDialog(context, service);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'add',
                      child: Row(
                        children: [
                          Icon(Icons.add, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('إضافة صيدلية'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.refresh, color: Colors.black54),
                          SizedBox(width: 8),
                          Text('تحديث'),
                        ],
                      ),
                    ),
                    if (service.pharmacies.isNotEmpty)
                      const PopupMenuItem(
                        value: 'clear',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('مسح البيانات', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
        body: Consumer<ReportService>(
          builder: (context, service, _) {
            if (service.isLoading) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('جاري التحميل...'),
                  ],
                ),
              );
            }

            if (service.pharmacies.isEmpty) {
              return _buildEmptyState(context, service);
            }

            if (service.error != null) {
              return _buildError(context, service);
            }

            return _buildPharmacyList(context, service);
          },
        ),
        floatingActionButton: Consumer<ReportService>(
          builder: (context, service, _) {
            if (service.pharmacies.isEmpty) return const SizedBox();
            return FloatingActionButton.extended(
              onPressed: () => _pickFiles(context, service),
              icon: const Icon(Icons.add),
              label: const Text('إضافة صيدلية'),
              backgroundColor: const Color(0xFF1E3C72),
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickFiles(BuildContext context, ReportService service) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final contents = <String>[];
        
        for (final file in result.files) {
          if (file.path != null) {
            final content = await File(file.path!).readAsString();
            contents.add(content);
          }
        }

        if (contents.isNotEmpty) {
          await service.loadMultipleFiles(contents);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('تم تحميل ${contents.length} ملف'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showClearDialog(BuildContext context, ReportService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مسح البيانات'),
        content: const Text('هل أنت متأكد من مسح جميع بيانات الصيدليات؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              service.clearData();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('مسح'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ReportService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3C72).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  'Rx',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    fontStyle: FontStyle.italic,
                    fontFamily: 'Georgia',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'تقارير الصيدلية',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'قم بتحميل ملفات التقارير من مجلد MobileReports',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _pickFiles(context, service),
              icon: const Icon(Icons.folder_open),
              label: const Text('اختيار ملفات التقارير'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3C72),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'المسار المتوقع للملفات:\nGoogle Drive > Sync > [رقم الصيدلية] > MobileReports > reports.json',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, ReportService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 24),
            Text(
              service.error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickFiles(context, service),
              icon: const Icon(Icons.folder_open),
              label: const Text('اختيار ملفات'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPharmacyList(BuildContext context, ReportService service) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // بطاقة "جميع الصيدليات"
        Card(
          color: const Color(0xFF1E3C72),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.search,
                color: Colors.white,
                size: 32,
              ),
            ),
            title: const Text(
              'جميع الصيدليات',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'بحث موحد في ${service.pharmacies.length} صيدلية',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            trailing: const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AllPharmaciesScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'الصيدليات',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${service.pharmacies.length} صيدلية',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // قائمة الصيدليات
        ...service.pharmacies.map((pharmacy) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3C72).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  pharmacy.id,
                  style: const TextStyle(
                    color: Color(0xFF1E3C72),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            title: Text(
              pharmacy.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: pharmacy.reports != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${pharmacy.reports!.inventoryList.data.length} صنف',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Text(
                        'آخر تحديث: ${pharmacy.reports!.meta.exportedAt}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  )
                : null,
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PharmacyScreen(pharmacy: pharmacy),
                ),
              );
            },
          ),
        )),
        const SizedBox(height: 80), // مساحة للـ FAB
      ],
    );
  }
}
