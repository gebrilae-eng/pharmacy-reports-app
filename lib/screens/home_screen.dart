import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
                if (service.isSignedIn) {
                  return PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) {
                      if (value == 'refresh') {
                        service.refresh();
                      } else if (value == 'change') {
                        service.clearFolder();
                      } else if (value == 'signout') {
                        service.signOut();
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'refresh',
                        child: Row(
                          children: [
                            Icon(Icons.refresh, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('تحديث البيانات'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'change',
                        child: Row(
                          children: [
                            Icon(Icons.folder_open, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('تغيير المجلد'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'signout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.black54),
                            SizedBox(width: 8),
                            Text('تسجيل الخروج'),
                          ],
                        ),
                      ),
                    ],
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

            // لو مش مسجل دخول
            if (!service.isSignedIn) {
              return _buildSignInScreen(context, service);
            }

            // لو مفيش مجلد Sync محدد
            if (!service.hasSyncFolder) {
              return _buildFolderSelection(context, service);
            }

            // لو فيه خطأ
            if (service.error != null) {
              return _buildError(context, service);
            }

            // عرض الصيدليات
            return _buildPharmacyList(context, service);
          },
        ),
      ),
    );
  }

  Widget _buildSignInScreen(BuildContext context, ReportService service) {
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
              'سجل الدخول بحساب Google للوصول إلى التقارير',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => service.signIn(),
              icon: Image.network(
                'https://www.google.com/favicon.ico',
                width: 24,
                height: 24,
                errorBuilder: (_, __, ___) => const Icon(Icons.login),
              ),
              label: const Text('تسجيل الدخول بـ Google'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black87,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                textStyle: const TextStyle(fontSize: 16),
                elevation: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderSelection(BuildContext context, ReportService service) {
    return FutureBuilder<List<DriveFolder>>(
      future: service.searchSyncFolders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('جاري البحث عن مجلد Sync...'),
              ],
            ),
          );
        }

        final folders = snapshot.data ?? [];

        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
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
                  'اختر مجلد Sync',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'تم العثور على ${folders.length} مجلد',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 24),
                if (folders.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange.shade700),
                        const SizedBox(height: 8),
                        Text(
                          'لم يتم العثور على مجلد Sync\nتأكد من وجود مجلد باسم Sync في Google Drive',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.orange.shade700),
                        ),
                      ],
                    ),
                  )
                else
                  ...folders.map((folder) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.folder, color: Color(0xFF1E3C72)),
                      title: Text(folder.name),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => service.selectSyncFolder(folder.id),
                    ),
                  )),
                const SizedBox(height: 24),
                TextButton.icon(
                  onPressed: () => service.signOut(),
                  icon: const Icon(Icons.logout),
                  label: const Text('تسجيل الخروج'),
                ),
              ],
            ),
          ),
        );
      },
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
              onPressed: () => service.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => service.clearFolder(),
              child: const Text('تغيير المجلد'),
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
        // معلومات المستخدم
        if (service.currentUser != null)
          Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: service.currentUser!.photoUrl != null
                    ? NetworkImage(service.currentUser!.photoUrl!)
                    : null,
                child: service.currentUser!.photoUrl == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              title: Text(service.currentUser!.displayName ?? ''),
              subtitle: Text(service.currentUser!.email),
            ),
          ),
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
              'بحث موحد في ${service.pharmacies.length} صيدليات',
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
        const Text(
          'الصيدليات',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
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
                ? Text(
                    '${pharmacy.reports!.inventoryList.data.length} صنف',
                    style: TextStyle(color: Colors.grey.shade600),
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
      ],
    );
  }
}
