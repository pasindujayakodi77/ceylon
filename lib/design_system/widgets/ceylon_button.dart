// FILE: lib/design_system/widgets/ceylon_button.dart
import 'package:flutter/material.dart';
import '../tokens.dart';

/// A button component that follows the Ceylon design system.
///
/// Provides three variants:
/// - primary: FilledButton for primary actions
/// - secondary: OutlinedButton for secondary actions
/// - tertiary: TextButton for tertiary actions
class CeylonButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final ButtonVariant variant;
  final bool isFullWidth;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final double? minHeight;
  final double? minWidth;
  final EdgeInsetsGeometry? padding;
  final Size? fixedSize;
  final Size? minimumSize;
  final double? iconSize;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final OutlinedBorder? shape;

  const CeylonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = ButtonVariant.primary,
    this.isFullWidth = false,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.minHeight,
    this.minWidth,
    this.padding,
    this.fixedSize,
    this.minimumSize,
    this.iconSize,
    this.textStyle,
    this.backgroundColor,
    this.foregroundColor,
    this.shape,
  });

  /// Creates a primary button (FilledButton) for main actions.
  factory CeylonButton.primary({
    required String label,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minHeight,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    Size? fixedSize,
    Size? minimumSize,
    double? iconSize,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? foregroundColor,
    OutlinedBorder? shape,
  }) {
    return CeylonButton(
      label: label,
      onPressed: onPressed,
      variant: ButtonVariant.primary,
      isFullWidth: isFullWidth,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      minHeight: minHeight,
      minWidth: minWidth,
      padding: padding,
      fixedSize: fixedSize,
      minimumSize: minimumSize,
      iconSize: iconSize,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: shape,
    );
  }

  /// Creates a secondary button (OutlinedButton) for alternative actions.
  factory CeylonButton.secondary({
    required String label,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minHeight,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    Size? fixedSize,
    Size? minimumSize,
    double? iconSize,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? foregroundColor,
    OutlinedBorder? shape,
  }) {
    return CeylonButton(
      label: label,
      onPressed: onPressed,
      variant: ButtonVariant.secondary,
      isFullWidth: isFullWidth,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      minHeight: minHeight,
      minWidth: minWidth,
      padding: padding,
      fixedSize: fixedSize,
      minimumSize: minimumSize,
      iconSize: iconSize,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: shape,
    );
  }

  /// Creates a tertiary button (TextButton) for lesser important actions.
  factory CeylonButton.tertiary({
    required String label,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
    bool isLoading = false,
    IconData? leadingIcon,
    IconData? trailingIcon,
    double? minHeight,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    Size? fixedSize,
    Size? minimumSize,
    double? iconSize,
    TextStyle? textStyle,
    Color? backgroundColor,
    Color? foregroundColor,
    OutlinedBorder? shape,
  }) {
    return CeylonButton(
      label: label,
      onPressed: onPressed,
      variant: ButtonVariant.tertiary,
      isFullWidth: isFullWidth,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      minHeight: minHeight,
      minWidth: minWidth,
      padding: padding,
      fixedSize: fixedSize,
      minimumSize: minimumSize,
      iconSize: iconSize,
      textStyle: textStyle,
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      shape: shape,
    );
  }

  @override
  Widget build(BuildContext context) {
    final effectiveMinimumSize =
        minimumSize ??
        Size(
          isFullWidth ? double.infinity : 0,
          minHeight ?? CeylonTokens.minTapArea,
        );

    final effectivePadding =
        padding ??
        const EdgeInsets.symmetric(
          horizontal: CeylonTokens.spacing20,
          vertical: CeylonTokens.spacing16,
        );

    final effectiveIconSize = iconSize ?? 18.0;

    final effectiveShape =
        shape ??
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(CeylonTokens.radiusMedium),
        );

    // Button content - same for all variants
    Widget buttonChild = Row(
      mainAxisSize: isFullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(width: CeylonTokens.spacing8),
        ] else ...[
          if (leadingIcon != null) ...[
            Icon(leadingIcon, size: effectiveIconSize),
            const SizedBox(width: CeylonTokens.spacing8),
          ],
        ],
        Text(label),
        if (trailingIcon != null && !isLoading) ...[
          const SizedBox(width: CeylonTokens.spacing8),
          Icon(trailingIcon, size: effectiveIconSize),
        ],
      ],
    );

    // Use the appropriate button variant
    switch (variant) {
      case ButtonVariant.primary:
        return FilledButton(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            minimumSize: effectiveMinimumSize,
            padding: effectivePadding,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: effectiveShape,
            fixedSize: fixedSize,
          ),
          child: buttonChild,
        );

      case ButtonVariant.secondary:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: effectiveMinimumSize,
            padding: effectivePadding,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: effectiveShape,
            fixedSize: fixedSize,
          ),
          child: buttonChild,
        );

      case ButtonVariant.tertiary:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            minimumSize: effectiveMinimumSize,
            padding: effectivePadding,
            textStyle: textStyle,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            shape: effectiveShape,
            fixedSize: fixedSize,
          ),
          child: buttonChild,
        );
    }
  }
}

/// Button variants following Material 3 guidelines.
enum ButtonVariant {
  /// Primary action (FilledButton)
  primary,

  /// Secondary action (OutlinedButton)
  secondary,

  /// Tertiary action (TextButton)
  tertiary,
}
