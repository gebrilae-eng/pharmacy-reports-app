import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import 'daily_screen.dart';
import 'shortages_screen.dart';
import 'inventory_screen.dart';
import 'balance_screen.dart';

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
                if (service.hasData) {
                  return IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () => service.refresh(),
                    tooltip: 'تحديث',
                  );
                }
                return const SizedBox.shrink();
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

            if (!service.hasData) {
              return _buildNoDataView(context, service);
            }

            return _buildReportsGrid(context, service);
          },
        ),
      ),
    );
  }

  Widget _buildNoDataView(BuildContext context, ReportService service) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              'لم يتم تحميل التقارير',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اختر مجلد MobileReports من Google Drive\nأو اختر ملف reports.json مباشرة',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            if (service.error != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  service.error!,
                  style: TextStyle(color: Colors.red.shade700),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => service.pickReportsFolder(),
              icon: const Icon(Icons.folder),
              label: const Text('اختيار مجلد'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => service.pickReportsFile(),
              icon: const Icon(Icons.file_open),
              label: const Text('اختيار ملف'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsGrid(BuildContext context, ReportService service) {
    final reports = service.reports!;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // معلومات الصيدلية
          _buildInfoCard(reports.meta),
          const SizedBox(height: 16),
          
          // آخر تحديث
          if (service.lastUpdate != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'آخر تحديث: ${_formatDateTime(service.lastUpdate!)}',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          
          // التقارير
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildReportCard(
                context,
                title: 'الجرد اليومي',
                icon: Icons.today,
                color: const Color(0xFF1E3C72),
                count: reports.dailyInventory.data.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DailyScreen()),
                ),
              ),
              _buildReportCard(
                context,
                title: 'النواقص',
                icon: Icons.warning_amber,
                color: Colors.red.shade600,
                count: reports.shortages.data.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ShortagesScreen()),
                ),
              ),
              _buildReportCard(
                context,
                title: 'المخزون',
                icon: Icons.inventory_2,
                color: Colors.green.shade600,
                count: reports.inventoryList.data.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const InventoryScreen()),
                ),
              ),
              _buildReportCard(
                context,
                title: 'بيان الأرصدة',
                icon: Icons.account_balance,
                color: Colors.purple.shade600,
                count: reports.balanceList.data.length,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BalanceScreen()),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // زر تغيير المصدر
          Center(
            child: TextButton.icon(
              onPressed: () => service.clear(),
              icon: const Icon(Icons.folder_open),
              label: const Text('تغيير مصدر البيانات'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(ReportMeta meta) {
    return Card(
      color: const Color(0xFF1E3C72),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (meta.hospitalName.isNotEmpty)
              Text(
                meta.hospitalName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            if (meta.pharmacyName.isNotEmpty)
              Text(
                meta.pharmacyName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                ),
              ),
            if (meta.directoryName.isNotEmpty)
              Text(
                meta.directoryName,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required int count,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '$count صنف',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
