# تطبيق تقارير الصيدلية - Rx

تطبيق موبايل لعرض تقارير نظام إدارة الصيدلية لعدة صيدليات.

---

## المميزات

- شعار Rx احترافي
- دعم عدة صيدليات
- بحث موحد في جميع الصيدليات
- 4 تقارير لكل صيدلية:
  - الجرد اليومي
  - النواقص
  - المخزون
  - بيان الأرصدة
- متوسط الاستهلاك اليومي
- إجمالي الرصيد من جميع الصيدليات
- طباعة/مشاركة PDF
- فلترة حسب الموقع
- بحث في الأصناف

---

## هيكل المجلدات المتوقع

```
Google Drive/
└── My Drive/
    └── Sync/
        ├── 1/
        │   └── MobileReports/
        │       └── reports.json
        ├── 2/
        │   └── MobileReports/
        │       └── reports.json
        └── 3/
            └── MobileReports/
                └── reports.json
```

---

## بناء APK عبر GitHub Actions

### 1. رفع الكود
```bash
cd mobile-app
git add .
git commit -m "Update app"
git push
```

### 2. البناء التلقائي
- اذهب إلى GitHub > Actions
- سيبدأ البناء تلقائياً
- انتظر 5-10 دقائق

### 3. تحميل APK
- بعد نجاح البناء
- اضغط على workflow
- حمل من Artifacts

---

## الملفات الرئيسية

```
lib/
├── main.dart                 # نقطة البدء
├── models/
│   └── report_models.dart    # موديلات البيانات
├── services/
│   └── report_service.dart   # خدمة التقارير
└── screens/
    ├── home_screen.dart           # الصفحة الرئيسية
    ├── all_pharmacies_screen.dart # البحث الموحد
    ├── pharmacy_screen.dart       # صفحة الصيدلية
    └── report_screen.dart         # صفحة التقرير
```

---

## الإصدار

- الإصدار: 1.0.0
- تاريخ التحديث: يناير 2026
