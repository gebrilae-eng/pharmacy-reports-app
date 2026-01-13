import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';
import '../widgets/medicine_card.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الجرد اليومي'),
        ),
        body: Consumer<ReportService>(
          builder: (context, service, _) {
            if (!service.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final report = service.reports!.dailyInventory;
            final medicines = service.searchMedicines(_searchQuery, report.data);
            final grouped = service.groupByLocation(medicines);

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
                
                // التاريخ والعدد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'التاريخ: ${report.date}',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E3C72),
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
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد أصناف مصروفة اليوم'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, index) {
                            final location = grouped.keys.elementAt(index);
                            final items = grouped[location]!;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (location.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Row(
                                      children: [
                                        Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          location,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '(${items.length})',
                                          style: TextStyle(color: Colors.grey.shade500),
                                        ),
                                      ],
                                    ),
                                  ),
                                ...items.map((med) => MedicineCard(
                                  medicine: med,
                                  showDispensed: true,
                                )),
                              ],
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
