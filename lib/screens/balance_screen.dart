import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';
import '../models/report_models.dart';
import '../widgets/medicine_card.dart';

class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بيان الأرصدة'),
          backgroundColor: Colors.purple.shade600,
        ),
        body: Consumer<ReportService>(
          builder: (context, service, _) {
            if (!service.hasData) {
              return const Center(child: Text('لا توجد بيانات'));
            }

            final report = service.reports!.balanceList;
            final medicines = service.searchMedicines(_searchQuery, report.data);
            final grouped = service.groupByLocation(medicines);
            
            // حساب الإجمالي
            double totalValue = 0;
            int totalStock = 0;
            for (var med in medicines) {
              totalValue += med.totalValue;
              totalStock += med.currentStock;
            }

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
                
                // الملخص
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade600, Colors.purple.shade400],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildSummaryItem(
                        icon: Icons.inventory_2,
                        label: 'الأصناف',
                        value: '${medicines.length}',
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildSummaryItem(
                        icon: Icons.shopping_bag,
                        label: 'إجمالي الكمية',
                        value: _formatNumber(totalStock),
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      _buildSummaryItem(
                        icon: Icons.attach_money,
                        label: 'إجمالي القيمة',
                        value: _formatCurrency(totalValue),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // القائمة
                Expanded(
                  child: medicines.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.account_balance, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              const Text('لا توجد أرصدة'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: grouped.keys.length,
                          itemBuilder: (context, index) {
                            final location = grouped.keys.elementAt(index);
                            final items = grouped[location]!;
                            
                            // حساب إجمالي الموقع
                            double locValue = 0;
                            for (var med in items) {
                              locValue += med.totalValue;
                            }
                            
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                  margin: const EdgeInsets.only(bottom: 8),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.location_on, size: 18, color: Colors.purple.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        location.isEmpty ? 'غير محدد' : location,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.purple.shade700,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _formatCurrency(locValue),
                                        style: TextStyle(
                                          color: Colors.purple.shade600,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                ...items.map((med) => MedicineCard(
                                  medicine: med,
                                  showBalance: true,
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

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(2)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(1)}K';
    }
    return amount.toStringAsFixed(2);
  }
}
