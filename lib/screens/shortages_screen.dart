import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';
import '../widgets/medicine_card.dart';

class ShortagesScreen extends StatefulWidget {
  const ShortagesScreen({super.key});

  @override
  State<ShortagesScreen> createState() => _ShortagesScreenState();
}

class _ShortagesScreenState extends State<ShortagesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('النواقص'),
          backgroundColor: Colors.red.shade600,
        ),
        body: Consumer<ReportService>(
          builder: (context, service, _) {
            if (!service.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final report = service.reports!.shortages;
            final medicines = service.searchMedicines(_searchQuery, report.data);

            return Column(
              children: [
                // شريط البحث
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) => setState(() => _searchQuery = value),
                  ),
                ),
                
                // العدد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning_amber, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'أصناف تحت الحد الأدنى',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.shade600,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${medicines.length} صنف',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // القائمة
                Expanded(
                  child: medicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, size: 64, color: Colors.green.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد نواقص'),
                              Text(
                                'جميع الأصناف فوق الحد الأدنى',
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: medicines.length,
                          itemBuilder: (context, index) {
                            return MedicineCard(
                              medicine: medicines[index],
                              showShortage: true,
                              highlightShortage: true,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
