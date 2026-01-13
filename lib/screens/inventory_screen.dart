import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';
import '../widgets/medicine_card.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String _selectedLocation = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('المخزون'),
          backgroundColor: Colors.green.shade600,
        ),
        body: Consumer<ReportService>(
          builder: (context, service, _) {
            if (!service.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final report = service.reports!.inventoryList;
            var medicines = service.searchMedicines(_searchQuery, report.data);
            
            // فلترة حسب الموقع
            if (_selectedLocation.isNotEmpty) {
              medicines = medicines.where((m) => m.location == _selectedLocation).toList();
            }
            
            final grouped = service.groupByLocation(medicines);
            final locations = report.data.map((m) => m.location).toSet().toList();
            locations.sort();

            return Column(
              children: [
                // شريط البحث
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: 'بحث...',
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (value) => setState(() => _searchQuery = value),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        icon: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _selectedLocation.isEmpty 
                                ? Colors.grey.shade200 
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.filter_list,
                            color: _selectedLocation.isEmpty 
                                ? Colors.grey.shade700 
                                : Colors.green.shade700,
                          ),
                        ),
                        onSelected: (value) {
                          setState(() {
                            _selectedLocation = value == 'all' ? '' : value;
                          });
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'all',
                            child: Text('الكل'),
                          ),
                          ...locations.map((loc) => PopupMenuItem(
                            value: loc,
                            child: Text(loc.isEmpty ? 'غير محدد' : loc),
                          )),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // العدد
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_selectedLocation.isNotEmpty)
                        Chip(
                          label: Text(_selectedLocation),
                          onDeleted: () => setState(() => _selectedLocation = ''),
                          deleteIcon: const Icon(Icons.close, size: 16),
                        )
                      else
                        Text(
                          'جميع المواقع',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600,
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
                              Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد أصناف'),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 18, color: Colors.green.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        location.isEmpty ? 'غير محدد' : location,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green.shade700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${items.length} صنف',
                                        style: TextStyle(
                                          color: Colors.green.shade600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...items.map((med) => MedicineCard(
                                  medicine: med,
                                  showStock: true,
                                  showExpiry: true,
                                )),
                                const SizedBox(height: 16),
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
