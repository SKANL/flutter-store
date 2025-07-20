import 'package:flutter/material.dart';
import 'package:store_manager/core/app_theme.dart';
import 'package:store_manager/screens/store_dashboard_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Store Manager',
      theme: AppTheme.lightTheme,
      home: const StoreDashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}