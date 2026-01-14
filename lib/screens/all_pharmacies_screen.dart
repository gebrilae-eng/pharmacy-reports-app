import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/report_service.dart';

class AllPharmaciesScreen extends StatefulWidget {
  const AllPharmaciesScreen({super.key});

  @override
  State<AllPharmaciesScreen> createState() => _AllPharmaciesScreenState();
}

class _AllPharmaciesScreenState extends State<AllPharmaciesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MedicineWithPharmacy> _results = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    final service = context.read<ReportService>();
    setState(() {
      _results = service.searchAllPharmacies(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('بحث في جميع الصيدليات'),
        ),
        body: Column(
          children: [
            // شريط البحث
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey.shade100,
              child: TextField(
                controller: _searchController,
                onChanged: _search,
                decoration: InputDecoration(
                  hintText: 'ابحث عن صنف...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _search('');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            // النتائج
            Expanded(
              child: _searchController.text.isEmpty
                  ? _buildSearchHint()
                  : _results.isEmpty
                      ? _buildNoResults()
                      : _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchHint() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'ابحث عن صنف',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'يمكنك البحث بالاسم العربي أو الإنجليزي أو العلمي',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'لا توجد نتائج',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    // تجميع النتائج حسب الصنف
    final Map<int, List<MedicineWithPharmacy>> grouped = {};
    for (final result in _results) {
      final id = result.medicine.medicineId;
      grouped[id] = (grouped[id] ?? [])..add(result);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final medicineId = grouped.keys.elementAt(index);
        final items = grouped[medicineId]!;
        final firstItem = items.first.medicine;

        // حساب الإجمالي
        int totalStock = 0;
        double totalAvg = 0;
        for (final item in items) {
          totalStock += item.medicine.stock;
          totalAvg += item.medicine.avgConsumption;
        }
        final avgConsumption = totalAvg / items.length;

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstItem.tradeNameAr.isNotEmpty 
                      ? firstItem.tradeNameAr 
                      : firstItem.tradeName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (firstItem.tradeName.isNotEmpty && firstItem.tradeNameAr.isNotEmpty)
                  Text(
                    firstItem.tradeName,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 14,
                    ),
                  ),
                if (firstItem.genericName.isNotEmpty)
                  Text(
                    firstItem.genericName,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  _buildChip(
                    icon: Icons.inventory_2,
                    label: 'إجمالي: $totalStock',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildChip(
                    icon: Icons.trending_down,
                    label: 'متوسط: ${avgConsumption.toStringAsFixed(1)}/يوم',
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
            children: [
              const Divider(),
              ...items.map((item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E3C72).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          item.pharmacy.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E3C72),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        item.pharmacy.name,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '${item.medicine.stock}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
