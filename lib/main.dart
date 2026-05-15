import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shop_manager/pages/welcome.dart';
import 'package:shop_manager/theme/app_themes.dart';

void main() {
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isDarkMode = false;

  void _onThemeChanged(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WelcomePage(
        isDarkMode: _isDarkMode,
        onThemeChanged: _onThemeChanged,
      ),
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme(),
      darkTheme: AppThemes.darkTheme(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
    );
  }
}
