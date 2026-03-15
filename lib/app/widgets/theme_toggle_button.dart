import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_science_academy/app/theme/theme_provider.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    bool isDarkMode = themeProvider.themeMode == ThemeMode.dark;

    return IconButton(
      icon: Icon(
        isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        color: Colors.white,
      ),
      tooltip: 'Toggle Theme',
      onPressed: () {
        final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
        themeProvider.setThemeMode(newMode);
      },
    );
  }
}
