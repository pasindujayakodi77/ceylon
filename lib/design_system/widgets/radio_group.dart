import 'package:flutter/material.dart';

/// A widget that manages a group of radio buttons.
/// 
/// RadioGroup provides a way to manage the selection state of a group of
/// Radio or RadioListTile widgets. It uses InheritedWidget to make the
/// group value and change handler available to descendant widgets.
///
/// This implementation addresses the deprecation of groupValue and onChanged
/// parameters in RadioListTile (deprecated after v3.32.0-0.0.pre).
///
/// Example:
/// ```dart
/// RadioGroup<ThemeMode>(
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
class RadioGroup<T> extends StatelessWidget {
  const RadioGroup({
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
    return _RadioGroupInherited<T>(
      groupValue: groupValue,
      onChanged: onChanged,
      child: child,
    );
  }

  /// Get the nearest RadioGroup ancestor from the context
  static _RadioGroupInherited<T>? of<T>(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RadioGroupInherited<T>>();
  }
}

class _RadioGroupInherited<T> extends InheritedWidget {
  const _RadioGroupInherited({
    required this.groupValue,
    required this.onChanged,
    required super.child,
  });

  final T? groupValue;
  final ValueChanged<T?>? onChanged;

  @override
  bool updateShouldNotify(_RadioGroupInherited<T> oldWidget) {
    return groupValue != oldWidget.groupValue || onChanged != oldWidget.onChanged;
  }
}
