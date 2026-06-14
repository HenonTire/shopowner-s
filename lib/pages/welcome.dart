import 'package:flutter/material.dart';
// import 'package:shop_manager/pages/login.dart';
// import 'package:shop_manager/pages/login.dart';
// // import 'package:shop_manager/pages/login.dart';
import 'package:shop_manager/pages/main_navigation_page.dart';

import 'package:shop_manager/theme/app_themes.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({
    super.key,
    required this.isDarkMode,
    required this.onThemeChanged,
  });

  final bool isDarkMode;
  final ValueChanged<bool> onThemeChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color bgTop =
        isDark ? const Color(0xFF172026) : const Color(0xFFEAF5EE);
    final Color bgBottom = scheme.surface;

    return Scaffold(
      backgroundColor: bgBottom,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[bgTop, bgBottom, bgBottom],
            stops: const <double>[0.0, 0.22, 1.0],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    tooltip: isDarkMode
                        ? 'Switch to light mode'
                        : 'Switch to dark mode',
                    onPressed: () => onThemeChanged(!isDarkMode),
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      color: scheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 200),
                Center(
                  child: Text(
                    'Shikela',
                    style: AppThemes.storyScript(
                      context,
                      fontSize: 45,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Center(
                  child: Text(
                    'shop manager',
                    style: AppThemes.poppins(
                      context,
                      fontSize: 18,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
                const SizedBox(height: 250),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MainNavigationPage(
                        isDarkMode: isDarkMode,
                        onThemeChanged: onThemeChanged,
                      ),
                    ),
                  ),
                  child: Container(
                    width: 250,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.onPrimary,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scheme.primary, width: 0.5),
                    ),
                    child: Text(
                      'Get Started',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w500,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
