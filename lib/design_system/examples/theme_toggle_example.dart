// FILE: lib/design_system/examples/theme_toggle_example.dart
import 'package:flutter/material.dart' hide RadioGroup;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../app_theme.dart';
import '../widgets/radio_group.dart';

/// Example theme toggle widget that can be integrated into Settings
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final colorScheme = Theme.of(context).colorScheme;
    final currentThemeMode = themeManager.themeMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Text(
            'Appearance',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
        ),
        RadioGroup<ThemeMode>(
          groupValue: currentThemeMode,
          onChanged: (ThemeMode? value) {
            if (value != null) {
              themeManager.setThemeMode(value);
              _saveThemeMode(value);
            }
          },
          child: Builder(
            builder: (context) {
              return Column(
                children: [
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('Light'),
                    value: ThemeMode.light,
                    // ignore: deprecated_member_use
                    groupValue: RadioGroup.groupValueOf<ThemeMode>(context),
                    // ignore: deprecated_member_use
                    onChanged: RadioGroup.onChangedOf<ThemeMode>(context),
                    secondary: const Icon(Icons.wb_sunny_outlined),
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('Dark'),
                    value: ThemeMode.dark,
                    // ignore: deprecated_member_use
                    groupValue: RadioGroup.groupValueOf<ThemeMode>(context),
                    // ignore: deprecated_member_use
                    onChanged: RadioGroup.onChangedOf<ThemeMode>(context),
                    secondary: const Icon(Icons.nightlight_outlined),
                  ),
                  // ignore: deprecated_member_use
                  RadioListTile<ThemeMode>(
                    title: const Text('System'),
                    value: ThemeMode.system,
                    // ignore: deprecated_member_use
                    groupValue: RadioGroup.groupValueOf<ThemeMode>(context),
                    // ignore: deprecated_member_use
                    onChanged: RadioGroup.onChangedOf<ThemeMode>(context),
                    secondary: const Icon(Icons.settings_outlined),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _saveThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String themeModeString;

    switch (mode) {
      case ThemeMode.light:
        themeModeString = 'light';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'system';
    }

    await prefs.setString('theme_mode', themeModeString);
  }
}
