import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:universal_science_academy/app/theme/theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text("Appearance", style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Column(
                children: [
                  RadioListTile<ThemeMode>(
                    title: const Text("Light Mode"),
                    value: ThemeMode.light,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("Dark Mode"),
                    value: ThemeMode.dark,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                  RadioListTile<ThemeMode>(
                    title: const Text("System Default"),
                    value: ThemeMode.system,
                    groupValue: themeProvider.themeMode,
                    onChanged: (value) => themeProvider.setThemeMode(value!),
                  ),
                ],
              ),
            ),
          ),
          // We can add more settings sections here later (e.g., Notifications, Language)
        ],
      ),
    );
  }
}
