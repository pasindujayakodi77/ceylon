import 'package:flutter/material.dart';

/// A widget that manages a group of radio buttons.
/// CeylonRadioGroup provides a way to manage the selection state of a group of
/// Radio or RadioListTile widgets. It uses InheritedWidget to make the
/// group value and change handler available to descendant widgets.
///
/// This implementation addresses the deprecation of groupValue and onChanged
/// parameters in RadioListTile (deprecated after v3.32.0-0.0.pre).
///
/// Example:
/// ```dart
/// CeylonRadioGroup<ThemeMode>(
///   groupValue: currentTheme,
///   onChanged: (value) => setState(() => currentTheme = value),
///   child: Column(
///     children: [
///       RadioListTile<ThemeMode>(
///         title: Text('Light'),
///         value: ThemeMode.light,
///       ),
///       RadioListTile<ThemeMode>(
///         title: Text('Dark'),
///         value: ThemeMode.dark,
///       ),
///     ],
///   ),
/// )
/// ```
class CeylonRadioGroup<T> extends StatelessWidget {
  const CeylonRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    required this.child,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RadioGroupInherited<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }

  /// Get the nearest CeylonRadioGroup ancestor from the context
  static RadioGroupInherited<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroupInherited<T>>();
  }

  /// Get the group value from the nearest RadioGroup ancestor
  static T? groupValueOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroupInherited<T>>()?.groupValue;
  }

  /// Get the onChanged callback from the nearest RadioGroup ancestor
  static ValueChanged<T?>? onChangedOf<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<RadioGroupInherited<T>>()?.onChanged;
  }
}

class RadioGroupInherited<T> extends InheritedWidget {
  const RadioGroupInherited({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  @override
  bool updateShouldNotify(RadioGroupInherited<T> oldWidget) {
    return groupValue != oldWidget.groupValue || onChanged != oldWidget.onChanged;
  }
}
