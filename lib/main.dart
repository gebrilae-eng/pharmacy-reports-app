import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/report_service.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const PharmacyReportsApp());
}

class PharmacyReportsApp extends StatelessWidget {
  const PharmacyReportsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReportService(),
      child: MaterialApp(
        title: 'تقارير الصيدلية',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3C72),
            brightness: Brightness.light,
          ),
          fontFamily: 'Cairo',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF1E3C72),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
