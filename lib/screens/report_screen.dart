import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/report_models.dart';

class ReportScreen extends StatefulWidget {
  final String type;
  final ReportData reportData;
  final String pharmacyName;

  const ReportScreen({
    super.key,
    required this.type,
    required this.reportData,
    required this.pharmacyName,
  });

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Medicine> _filteredItems = [];
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.reportData.data;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _locations {
    final locations = widget.reportData.data
        .map((m) => m.location)
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList();
    locations.sort();
    return locations;
  }

  void _filter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredItems = widget.reportData.data.where((m) {
        final matchesSearch = query.isEmpty ||
            m.tradeNameAr.toLowerCase().contains(query) ||
            m.tradeName.toLowerCase().contains(query) ||
            m.genericName.toLowerCase().contains(query);
        final matchesLocation =
            _selectedLocation == null || m.location == _selectedLocation;
        return matchesSearch && matchesLocation;
      }).toList();
    });
  }

  String get _title {
    switch (widget.type) {
      case 'daily':
        return 'الجرد اليومي';
      case 'shortages':
        return 'النواقص';
      case 'inventory':
        return 'المخزون';
      case 'balance':
        return 'بيان الأرصدة';
      default:
        return widget.reportData.title;
    }
  }

  Color get _color {
    switch (widget.type) {
      case 'daily':
        return const Color(0xFF1E3C72);
      case 'shortages':
        return Colors.red.shade600;
      case 'inventory':
        return Colors.green.shade600;
      case 'balance':
        return Colors.purple.shade600;
      default:
        return const Color(0xFF1E3C72);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_title),
          backgroundColor: _color,
          actions: [
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'طباعة',
              onPressed: _printReport,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'مشاركة',
              onPressed: _shareReport,
            ),
          ],
        ),
        body: Column(
          children: [
            // شريط البحث والفلترة
            Container(
              padding: const EdgeInsets.all(12),
              color: Colors.grey.shade100,
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => _filter(),
                    decoration: InputDecoration(
                      hintText: 'بحث...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _filter();
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                  if (_locations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterChip('الكل', null),
                          ..._locations.map((loc) => _buildFilterChip(loc, loc)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // ملخص
            _buildSummary(),
            // القائمة
            Expanded(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد أصناف',
                        style: TextStyle(color: Colors.grey.shade500),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        return _buildItemCard(_filteredItems[index]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? value) {
    final isSelected = _selectedLocation == value;
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            _selectedLocation = value;
          });
          _filter();
        },
        selectedColor: _color.withOpacity(0.2),
        checkmarkColor: _color,
      ),
    );
  }

  Widget _buildSummary() {
    int totalStock = 0;
    double totalValue = 0;
    int totalDispensed = 0;

    for (final item in _filteredItems) {
      totalStock += item.stock;
      totalValue += item.totalValue;
      totalDispensed += item.totalDispensed;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem(
            icon: Icons.inventory_2,
            label: 'الأصناف',
            value: '${_filteredItems.length}',
            color: _color,
          ),
          if (widget.type == 'daily')
            _buildSummaryItem(
              icon: Icons.shopping_cart,
              label: 'المصروف',
              value: '$totalDispensed',
              color: Colors.orange,
            )
          else
            _buildSummaryItem(
              icon: Icons.storage,
              label: 'إجمالي الكمية',
              value: '$totalStock',
              color: Colors.blue,
            ),
          if (widget.type == 'balance')
            _buildSummaryItem(
              icon: Icons.attach_money,
              label: 'القيمة',
              value: totalValue.toStringAsFixed(0),
              color: Colors.purple,
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildItemCard(Medicine item) {
    final isShortage = widget.type == 'shortages' ||
        (item.minStock > 0 && item.stock < item.minStock);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isShortage
            ? BorderSide(color: Colors.red.shade300, width: 1)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.tradeNameAr.isNotEmpty
                        ? item.tradeNameAr
                        : item.tradeName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                if (item.form.isNotEmpty || item.strength.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      [item.strength, item.form]
                          .where((s) => s.isNotEmpty)
                          .join(' '),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            if (item.tradeName.isNotEmpty && item.tradeNameAr.isNotEmpty)
              Text(
                item.tradeName,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            if (item.genericName.isNotEmpty)
              Text(
                item.genericName,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildChip(
                  icon: Icons.inventory_2,
                  label: 'الرصيد: ${item.stock}',
                  color: isShortage ? Colors.red : Colors.blue,
                ),
                if (widget.type == 'daily' && item.totalDispensed > 0)
                  _buildChip(
                    icon: Icons.shopping_cart,
                    label: 'مصروف: ${item.totalDispensed}',
                    color: Colors.orange,
                  ),
                if (item.avgConsumption > 0)
                  _buildChip(
                    icon: Icons.trending_down,
                    label: 'متوسط: ${item.avgConsumption.toStringAsFixed(1)}/يوم',
                    color: Colors.teal,
                  ),
                if (widget.type == 'shortages' && item.minStock > 0)
                  _buildChip(
                    icon: Icons.warning,
                    label: 'الحد الأدنى: ${item.minStock}',
                    color: Colors.grey,
                  ),
                if (widget.type == 'balance' && item.totalValue > 0)
                  _buildChip(
                    icon: Icons.attach_money,
                    label: 'القيمة: ${item.totalValue.toStringAsFixed(2)}',
                    color: Colors.purple,
                  ),
                if (item.nearestExpiry.isNotEmpty)
                  _buildChip(
                    icon: Icons.event,
                    label: 'الصلاحية: ${_formatDate(item.nearestExpiry)}',
                    color: _isNearExpiry(item.nearestExpiry)
                        ? Colors.orange
                        : Colors.green,
                  ),
              ],
            ),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  bool _isNearExpiry(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final diff = date.difference(DateTime.now()).inDays;
      return diff <= 90;
    } catch (_) {
      return false;
    }
  }

  Future<void> _printReport() async {
    final pdf = await _generatePdf();
    await Printing.layoutPdf(onLayout: (format) => pdf);
  }

  Future<void> _shareReport() async {
    final pdf = await _generatePdf();
    await Printing.sharePdf(bytes: pdf, filename: '${_title}.pdf');
  }

  Future<List<int>> _generatePdf() async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBoldFont = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(
          base: arabicFont,
          bold: arabicBoldFont,
        ),
        textDirection: pw.TextDirection.rtl,
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  widget.pharmacyName,
                  style: pw.TextStyle(
                    font: arabicBoldFont,
                    fontSize: 16,
                  ),
                ),
                pw.Text(
                  _title,
                  style: pw.TextStyle(
                    font: arabicBoldFont,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'التاريخ: ${widget.reportData.date}',
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
            pw.Divider(),
            pw.SizedBox(height: 8),
          ],
        ),
        footer: (context) => pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'صفحة ${context.pageNumber} من ${context.pagesCount}',
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
            pw.Text(
              'Rx تقارير الصيدلية',
              style: pw.TextStyle(font: arabicFont, fontSize: 10),
            ),
          ],
        ),
        build: (context) => [
          pw.Table.fromTextArray(
            context: context,
            headerStyle: pw.TextStyle(
              font: arabicBoldFont,
              fontSize: 10,
            ),
            cellStyle: pw.TextStyle(
              font: arabicFont,
              fontSize: 9,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellAlignments: {
              0: pw.Alignment.centerRight,
              1: pw.Alignment.centerRight,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
            headers: _getHeaders(),
            data: _filteredItems.map((item) => _getRowData(item)).toList(),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  List<String> _getHeaders() {
    switch (widget.type) {
      case 'daily':
        return ['الاسم', 'المادة الفعالة', 'الرصيد', 'المصروف', 'المتوسط'];
      case 'shortages':
        return ['الاسم', 'المادة الفعالة', 'الرصيد', 'الحد الأدنى', 'المتوسط'];
      case 'balance':
        return ['الاسم', 'المادة الفعالة', 'الرصيد', 'القيمة', 'المتوسط'];
      default:
        return ['الاسم', 'المادة الفعالة', 'الرصيد', 'الصلاحية', 'المتوسط'];
    }
  }

  List<String> _getRowData(Medicine item) {
    final name = item.tradeNameAr.isNotEmpty ? item.tradeNameAr : item.tradeName;
    switch (widget.type) {
      case 'daily':
        return [
          name,
          item.genericName,
          '${item.stock}',
          '${item.totalDispensed}',
          item.avgConsumption.toStringAsFixed(1),
        ];
      case 'shortages':
        return [
          name,
          item.genericName,
          '${item.stock}',
          '${item.minStock}',
          item.avgConsumption.toStringAsFixed(1),
        ];
      case 'balance':
        return [
          name,
          item.genericName,
          '${item.stock}',
          item.totalValue.toStringAsFixed(2),
          item.avgConsumption.toStringAsFixed(1),
        ];
      default:
        return [
          name,
          item.genericName,
          '${item.stock}',
          _formatDate(item.nearestExpiry),
          item.avgConsumption.toStringAsFixed(1),
        ];
    }
  }
}
