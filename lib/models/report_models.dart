// موديلات البيانات

class ReportMeta {
  final String exportedAt;
  final String pharmacyId;
  final String pharmacyName;
  final String hospitalName;
  final String directoryName;

  ReportMeta({
    required this.exportedAt,
    required this.pharmacyId,
    required this.pharmacyName,
    required this.hospitalName,
    required this.directoryName,
  });

  factory ReportMeta.fromJson(Map<String, dynamic> json) {
    return ReportMeta(
      exportedAt: json['exported_at'] ?? '',
      pharmacyId: json['pharmacy_id']?.toString() ?? '1',
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
  final int totalStock;
  final int totalDispensed;
  final int minStock;
  final double totalValue;
  final double avgConsumption;
  final int coverageDays;
  final String nearestExpiry;

  Medicine({
    required this.medicineId,
    required this.tradeName,
    required this.tradeNameAr,
    required this.genericName,
    required this.strength,
    required this.form,
    required this.location,
    required this.currentStock,
    required this.totalStock,
    required this.totalDispensed,
    required this.minStock,
    required this.totalValue,
    required this.avgConsumption,
    required this.coverageDays,
    required this.nearestExpiry,
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
      currentStock: int.tryParse(json['current_stock']?.toString() ?? '0') ?? 0,
      totalStock: int.tryParse(json['total_stock']?.toString() ?? '0') ?? 0,
      totalDispensed: int.tryParse(json['total_dispensed']?.toString() ?? '0') ?? 0,
      minStock: int.tryParse(json['min_stock']?.toString() ?? '0') ?? 0,
      totalValue: double.tryParse(json['total_value']?.toString() ?? '0') ?? 0,
      avgConsumption: double.tryParse(json['avg_consumption']?.toString() ?? '0') ?? 0,
      coverageDays: int.tryParse(json['coverage_days']?.toString() ?? '999') ?? 999,
      nearestExpiry: json['nearest_expiry'] ?? '',
    );
  }

  int get stock => currentStock > 0 ? currentStock : totalStock;
  
  String get coverageText {
    if (coverageDays >= 999 || avgConsumption <= 0) return '-';
    return '$coverageDays يوم';
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
          ?.map((e) => Medicine.fromJson(e))
          .toList() ?? [],
    );
  }
}

class PharmacyReports {
  final ReportMeta meta;
  final ReportData dailyInventory;
  final ReportData shortages;
  final ReportData inventoryList;
  final ReportData balanceList;

  PharmacyReports({
    required this.meta,
    required this.dailyInventory,
    required this.shortages,
    required this.inventoryList,
    required this.balanceList,
  });

  factory PharmacyReports.fromJson(Map<String, dynamic> json) {
    return PharmacyReports(
      meta: ReportMeta.fromJson(json['meta'] ?? {}),
      dailyInventory: ReportData.fromJson(json['daily_inventory'] ?? {}),
      shortages: ReportData.fromJson(json['shortages'] ?? {}),
      inventoryList: ReportData.fromJson(json['inventory_list'] ?? {}),
      balanceList: ReportData.fromJson(json['balance_list'] ?? {}),
    );
  }
}

class Pharmacy {
  final String id;
  final String name;
  final String folderPath;
  final PharmacyReports? reports;

  Pharmacy({
    required this.id,
    required this.name,
    required this.folderPath,
    this.reports,
  });

  Pharmacy copyWith({PharmacyReports? reports}) {
    return Pharmacy(
      id: id,
      name: name,
      folderPath: folderPath,
      reports: reports ?? this.reports,
    );
  }
}
