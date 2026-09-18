// Update main.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'features/document_scan/presentation/screens/scan_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // UI overlay settings now handled inside the lightTheme's appBarTheme
  runApp(const QuickPDFApp());
}

class QuickPDFApp extends StatelessWidget {
  const QuickPDFApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'QuickPDF',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme, // CHANGE HERE: Point to the new light theme
      home: const ScanHomeScreen(),
    );
  }
}
