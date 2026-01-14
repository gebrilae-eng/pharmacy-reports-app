import 'package:flutter/material.dart';
import '../models/report_models.dart';
import 'report_screen.dart';

class PharmacyScreen extends StatefulWidget {
  final Pharmacy pharmacy;

  const PharmacyScreen({super.key, required this.pharmacy});

  @override
  State<PharmacyScreen> createState() => _PharmacyScreenState();
}

class _PharmacyScreenState extends State<PharmacyScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredItems = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.pharmacy.reports?.inventoryList.data ?? [];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    if (widget.pharmacy.reports == null) return;

    setState(() {
      _isSearching = query.isNotEmpty;
      if (query.isEmpty) {
        _filteredItems = widget.pharmacy.reports!.inventoryList.data;
      } else {
        final queryLower = query.toLowerCase();
        _filteredItems = widget.pharmacy.reports!.inventoryList.data
            .where((m) =>
                m.tradeNameAr.toLowerCase().contains(queryLower) ||
                m.tradeName.toLowerCase().contains(queryLower) ||
                m.genericName.toLowerCase().contains(queryLower))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final reports = widget.pharmacy.reports;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.pharmacy.name),
        ),
        body: reports == null
            ? const Center(child: Text('لا توجد بيانات'))
            : Column(
                children: [
                  // شريط البحث
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade100,
                    child: TextField(
                      controller: _searchController,
                      onChanged: _search,
                      decoration: InputDecoration(
                        hintText: 'بحث في الأصناف...',
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
                  // المحتوى
                  Expanded(
                    child: _isSearching
                        ? _buildSearchResults()
                        : _buildMainContent(reports),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMainContent(PharmacyReports reports) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // معلومات الصيدلية
        if (reports.meta.hospitalName.isNotEmpty ||
            reports.meta.pharmacyName.isNotEmpty)
          Card(
            color: const Color(0xFF1E3C72),
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (reports.meta.hospitalName.isNotEmpty)
                    Text(
                      reports.meta.hospitalName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (reports.meta.pharmacyName.isNotEmpty)
                    Text(
                      reports.meta.pharmacyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'آخر تحديث: ${reports.meta.exportedAt}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        // التقارير
        const Text(
          'التقارير',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: [
            _buildReportCard(
              title: 'الجرد اليومي',
              icon: Icons.today,
              color: const Color(0xFF1E3C72),
              count: reports.dailyInventory.data.length,
              onTap: () => _openReport('daily', reports.dailyInventory),
            ),
            _buildReportCard(
              title: 'النواقص',
              icon: Icons.warning_amber,
              color: Colors.red.shade600,
              count: reports.shortages.data.length,
              onTap: () => _openReport('shortages', reports.shortages),
            ),
            _buildReportCard(
              title: 'المخزون',
              icon: Icons.inventory_2,
              color: Colors.green.shade600,
              count: reports.inventoryList.data.length,
              onTap: () => _openReport('inventory', reports.inventoryList),
            ),
            _buildReportCard(
              title: 'بيان الأرصدة',
              icon: Icons.account_balance,
              color: Colors.purple.shade600,
              count: reports.balanceList.data.length,
              onTap: () => _openReport('balance', reports.balanceList),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReportCard({
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
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
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

  Widget _buildSearchResults() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'لا توجد نتائج',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredItems.length,
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(
              item.tradeNameAr.isNotEmpty ? item.tradeNameAr : item.tradeName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.tradeName.isNotEmpty && item.tradeNameAr.isNotEmpty)
                  Text(item.tradeName),
                if (item.genericName.isNotEmpty)
                  Text(
                    item.genericName,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildMiniChip('الرصيد: ${item.stock}', Colors.blue),
                    const SizedBox(width: 8),
                    _buildMiniChip(
                      'متوسط: ${item.avgConsumption.toStringAsFixed(1)}/يوم',
                      Colors.orange,
                    ),
                  ],
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildMiniChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color),
      ),
    );
  }

  void _openReport(String type, ReportData reportData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReportScreen(
          type: type,
          reportData: reportData,
          pharmacyName: widget.pharmacy.name,
        ),
      ),
    );
  }
}
