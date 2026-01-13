# تطبيق تقارير الصيدلية - Flutter

تطبيق موبايل لعرض تقارير نظام إدارة الصيدلية.

---

## بناء APK عبر GitHub Actions

### الخطوات:

#### 1. إنشاء مستودع GitHub جديد
- اذهب إلى https://github.com/new
- أنشئ مستودع جديد باسم `pharmacy-reports-app`
- اتركه فارغاً (بدون README)

#### 2. رفع الملفات إلى GitHub
افتح Command Prompt في مجلد `mobile-app`:

```bash
cd C:\laragon\www\pharmacy-system\mobile-app

git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/USERNAME/pharmacy-reports-app.git
git push -u origin main
```
**استبدل `USERNAME` باسم حسابك على GitHub**

#### 3. تشغيل البناء
- اذهب إلى صفحة المستودع على GitHub
- اضغط على تبويب **Actions**
- اضغط على **Build Flutter APK**
- اضغط على **Run workflow** > **Run workflow**

#### 4. تحميل APK
- انتظر حتى ينتهي البناء (5-10 دقائق)
- اضغط على الـ workflow الذي انتهى
- في قسم **Artifacts** ستجد `pharmacy-reports-apk`
- اضغط لتحميل ملف APK

---

## البناء المحلي (يحتاج Flutter SDK)

```bash
# تثبيت التبعيات
flutter pub get

# بناء APK
flutter build apk --release

# الملف الناتج
build/app/outputs/flutter-apk/app-release.apk
```

---

## هيكل المشروع

```
mobile-app/
├── .github/
│   └── workflows/
│       └── build-apk.yml    # GitHub Actions workflow
├── android/                  # ملفات Android
├── lib/
│   ├── main.dart            # نقطة البدء
│   ├── models/              # موديلات البيانات
│   ├── services/            # خدمات التطبيق
│   ├── screens/             # الشاشات
│   └── widgets/             # الويدجتس
├── assets/                   # الأصول
└── pubspec.yaml             # تعريف المشروع
```

---

## التقارير المتاحة

| # | التقرير | الوصف |
|---|---------|-------|
| 1 | الجرد اليومي | الأصناف المصروفة اليوم |
| 2 | النواقص | الأصناف تحت الحد الأدنى |
| 3 | المخزون | جميع الأصناف مع الكميات |
| 4 | بيان الأرصدة | الأرصدة مع القيم المالية |

---

## طريقة الاستخدام

1. افتح التطبيق
2. اضغط على "اختيار ملف" أو "اختيار مجلد"
3. حدد ملف `reports.json` من مجلد `MobileReports`
4. استعرض التقارير المختلفة

---

## الميزات

- دعم كامل للغة العربية (RTL)
- بحث في الأصناف
- فلترة حسب الموقع
- تصميم Material Design 3
- حفظ مسار الملف تلقائياً
- يعمل Offline

---

## الإصدار

- الإصدار: 1.0.0
- تاريخ الإنشاء: يناير 2026
