// FILE: lib/design_system/widgets/ceylon_app_bar.dart
import 'package:flutter/material.dart';
import '../tokens.dart';

/// A custom app bar component with two variants: large and medium.
/// 
/// The large variant is typically used for detail screens with a more prominent title.
/// The medium variant is used for list screens and provides a balanced appearance.
class CeylonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final bool? centerTitle;
  final Widget? flexibleSpace;
  final double? elevation;
  final double toolbarHeight;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final TextStyle? titleTextStyle;
  final bool isLarge;

  const CeylonAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.centerTitle,
    this.flexibleSpace,
    this.elevation,
    this.backgroundColor,
    this.foregroundColor,
    this.titleTextStyle,
    this.isLarge = false,
    double? toolbarHeight,
  }) : toolbarHeight = toolbarHeight ?? (isLarge ? 128.0 : kToolbarHeight);

  /// Creates a large variant of the app bar, typically used for detail screens.
  factory CeylonAppBar.large({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool? centerTitle,
    Widget? flexibleSpace,
    double? elevation,
    Color? backgroundColor,
    Color? foregroundColor,
    TextStyle? titleTextStyle,
  }) {
    return CeylonAppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      flexibleSpace: flexibleSpace,
      elevation: elevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      titleTextStyle: titleTextStyle,
      isLarge: true,
    );
  }

  /// Creates a medium variant of the app bar, typically used for list screens.
  factory CeylonAppBar.medium({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    bool? centerTitle,
    Widget? flexibleSpace,
    double? elevation,
    Color? backgroundColor,
    Color? foregroundColor,
    TextStyle? titleTextStyle,
  }) {
    return CeylonAppBar(
      title: title,
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle,
      flexibleSpace: flexibleSpace,
      elevation: elevation,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      titleTextStyle: titleTextStyle,
      isLarge: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Determine title style based on app bar size
    final effectiveTitleStyle = titleTextStyle ?? 
        (isLarge 
            ? textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)
            : textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600));

    return AppBar(
      title: Padding(
        padding: isLarge 
            ? const EdgeInsets.only(bottom: CeylonTokens.spacing16)
            : EdgeInsets.zero,
        child: Text(title),
      ),
      actions: actions,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      centerTitle: centerTitle ?? false,
      flexibleSpace: flexibleSpace,
      elevation: elevation ?? 0,
      scrolledUnderElevation: 2,
      toolbarHeight: toolbarHeight,
      backgroundColor: backgroundColor ?? colorScheme.surface,
      foregroundColor: foregroundColor ?? colorScheme.onSurface,
      titleTextStyle: effectiveTitleStyle,
      titleSpacing: CeylonTokens.spacing16,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(toolbarHeight);
}
