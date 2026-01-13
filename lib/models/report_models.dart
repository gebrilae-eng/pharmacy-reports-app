// موديلات بيانات التقارير

class ReportMeta {
  final String exportedAt;
  final String pharmacyName;
  final String hospitalName;
  final String directoryName;

  ReportMeta({
    required this.exportedAt,
    required this.pharmacyName,
    required this.hospitalName,
    required this.directoryName,
  });

  factory ReportMeta.fromJson(Map<String, dynamic> json) {
    return ReportMeta(
      exportedAt: json['exported_at'] ?? '',
      pharmacyName: json['pharmacy_name'] ?? '',
      hospitalName: json['hospital_name'] ?? '',
      directoryName: json['directory_name'] ?? '',
    );
  }
}

class Medicine {
  final int medicineId;
  final String tradeName;
  final String tradeNameAr;
  final String genericName;
  final String strength;
  final String form;
  final String location;
  final int currentStock;
  final int minStock;
  final int totalDispensed;
  final double totalValue;
  final String nearestExpiry;
  final int batches;

  Medicine({
    required this.medicineId,
    required this.tradeName,
    required this.tradeNameAr,
    required this.genericName,
    required this.strength,
    required this.form,
    required this.location,
    this.currentStock = 0,
    this.minStock = 0,
    this.totalDispensed = 0,
    this.totalValue = 0,
    this.nearestExpiry = '',
    this.batches = 0,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) {
    return Medicine(
      medicineId: json['medicine_id'] ?? 0,
      tradeName: json['trade_name'] ?? '',
      tradeNameAr: json['trade_name_ar'] ?? '',
      genericName: json['generic_name'] ?? '',
      strength: json['strength'] ?? '',
      form: json['form'] ?? '',
      location: json['location'] ?? '',
      currentStock: _parseInt(json['current_stock'] ?? json['total_stock']),
      minStock: _parseInt(json['min_stock']),
      totalDispensed: _parseInt(json['total_dispensed']),
      totalValue: _parseDouble(json['total_value']),
      nearestExpiry: json['nearest_expiry'] ?? '',
      batches: _parseInt(json['batches']),
    );
  }

  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  // الاسم المعروض (العربي أو الإنجليزي)
  String get displayName => tradeNameAr.isNotEmpty ? tradeNameAr : tradeName;
  
  // هل الصنف ناقص؟
  bool get isShortage => currentStock < minStock;
  
  // هل قارب على الانتهاء؟
  bool get isNearExpiry {
    if (nearestExpiry.isEmpty) return false;
    try {
      final expiry = DateTime.parse(nearestExpiry);
      final now = DateTime.now();
      return expiry.difference(now).inDays <= 90;
    } catch (_) {
      return false;
    }
  }
}

class ReportData {
  final String title;
  final String date;
  final List<Medicine> data;

  ReportData({
    required this.title,
    required this.date,
    required this.data,
  });

  factory ReportData.fromJson(Map<String, dynamic> json) {
    return ReportData(
      title: json['title'] ?? '',
      date: json['date'] ?? '',
      data: (json['data'] as List<dynamic>?)
              ?.map((item) => Medicine.fromJson(item))
              .toList() ??
          [],
    );
  }
}

class AllReports {
  final ReportMeta meta;
  final ReportData dailyInventory;
  final ReportData shortages;
  final ReportData inventoryList;
  final ReportData balanceList;

  AllReports({
    required this.meta,
    required this.dailyInventory,
    required this.shortages,
    required this.inventoryList,
    required this.balanceList,
  });

  factory AllReports.fromJson(Map<String, dynamic> json) {
    return AllReports(
      meta: ReportMeta.fromJson(json['meta'] ?? {}),
      dailyInventory: ReportData.fromJson(json['daily_inventory'] ?? {}),
      shortages: ReportData.fromJson(json['shortages'] ?? {}),
      inventoryList: ReportData.fromJson(json['inventory_list'] ?? {}),
      balanceList: ReportData.fromJson(json['balance_list'] ?? {}),
    );
  }
}
