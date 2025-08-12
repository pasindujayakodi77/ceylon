// FILE: lib/design_system/app_theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tokens.dart';

/// Custom theme extension to provide additional design tokens
class CeylonThemeExtension extends ThemeExtension<CeylonThemeExtension> {
  final BorderRadius borderRadiusSmall;
  final BorderRadius borderRadiusMedium; 
  final BorderRadius borderRadiusLarge;
  final List<BoxShadow> shadowSmall;
  final List<BoxShadow> shadowMedium;
  final List<BoxShadow> shadowLarge;
  
  CeylonThemeExtension({
    required this.borderRadiusSmall,
    required this.borderRadiusMedium,
    required this.borderRadiusLarge,
    required this.shadowSmall,
    required this.shadowMedium,
    required this.shadowLarge,
  });

  @override
  ThemeExtension<CeylonThemeExtension> copyWith({
    BorderRadius? borderRadiusSmall,
    BorderRadius? borderRadiusMedium,
    BorderRadius? borderRadiusLarge,
    List<BoxShadow>? shadowSmall,
    List<BoxShadow>? shadowMedium,
    List<BoxShadow>? shadowLarge,
  }) {
    return CeylonThemeExtension(
      borderRadiusSmall: borderRadiusSmall ?? this.borderRadiusSmall,
      borderRadiusMedium: borderRadiusMedium ?? this.borderRadiusMedium,
      borderRadiusLarge: borderRadiusLarge ?? this.borderRadiusLarge,
      shadowSmall: shadowSmall ?? this.shadowSmall,
      shadowMedium: shadowMedium ?? this.shadowMedium,
      shadowLarge: shadowLarge ?? this.shadowLarge,
    );
  }

  @override
  ThemeExtension<CeylonThemeExtension> lerp(
      covariant ThemeExtension<CeylonThemeExtension>? other, double t) {
    if (other is! CeylonThemeExtension) {
      return this;
    }
    return this;
  }
  
  /// Get the extension from the current theme
  static CeylonThemeExtension of(BuildContext context) {
    return Theme.of(context).extension<CeylonThemeExtension>()!;
  }
}

/// Theme provider class containing light and dark theme data
class AppTheme {
  // Base seed color for generating color schemes
  static const Color _seedColor = CeylonTokens.seedColor;

  // Private constructor to prevent instantiation
  AppTheme._();
  
  /// Light theme data
  static ThemeData get lightTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.light,
      background: CeylonTokens.lightBackground,
      surface: CeylonTokens.lightSurface,
    );
    
    return _baseTheme(colorScheme).copyWith(
      brightness: Brightness.light,
    );
  }

  /// Dark theme data
  static ThemeData get darkTheme {
    final ColorScheme colorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor,
      brightness: Brightness.dark,
      background: CeylonTokens.darkBackground,
      surface: CeylonTokens.darkSurface,
    );
    
    return _baseTheme(colorScheme).copyWith(
      brightness: Brightness.dark,
    );
  }

  /// Base theme configuration common to both light and dark themes
  static ThemeData _baseTheme(ColorScheme colorScheme) {
    final TextTheme textTheme = _buildTextTheme();
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      textTheme: textTheme,
      fontFamily: GoogleFonts.inter().fontFamily,
      
      // Card theme
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
        ),
        clipBehavior: Clip.antiAlias,
        margin: EdgeInsets.zero,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing20,
            vertical: CeylonTokens.spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CeylonTokens.borderRadiusMedium,
          ),
          minimumSize: const Size(0, CeylonTokens.minTapArea),
        ),
      ),
      
      // Filled button theme (primary actions)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing20,
            vertical: CeylonTokens.spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CeylonTokens.borderRadiusMedium,
          ),
          minimumSize: const Size(0, CeylonTokens.minTapArea),
        ),
      ),
      
      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing20,
            vertical: CeylonTokens.spacing16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CeylonTokens.borderRadiusMedium,
          ),
          side: BorderSide(color: colorScheme.outline),
          minimumSize: const Size(0, CeylonTokens.minTapArea),
        ),
      ),
      
      // Text button theme (tertiary actions)
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: CeylonTokens.spacing16,
            vertical: CeylonTokens.spacing12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: CeylonTokens.borderRadiusMedium,
          ),
          minimumSize: const Size(0, CeylonTokens.minTapArea),
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
        border: OutlineInputBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CeylonTokens.spacing16,
          vertical: CeylonTokens.spacing16,
        ),
      ),
      
      // Chip theme
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: CeylonTokens.borderRadiusSmall,
        ),
        side: BorderSide(color: colorScheme.outlineVariant),
        padding: const EdgeInsets.symmetric(
          horizontal: CeylonTokens.spacing12,
          vertical: CeylonTokens.spacing8,
        ),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        elevation: 8,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
      ),
      
      // List tile theme
      listTileTheme: ListTileThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: CeylonTokens.spacing16,
          vertical: CeylonTokens.spacing12,
        ),
        minLeadingWidth: 24,
        minVerticalPadding: CeylonTokens.spacing12,
      ),
      
      // Dialog theme
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
        ),
        elevation: 8,
      ),
      
      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: CeylonTokens.borderRadiusMedium,
        ),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onInverseSurface,
        ),
        actionTextColor: colorScheme.primaryContainer,
      ),
      
      // Custom theme extensions
      extensions: [
        CeylonThemeExtension(
          borderRadiusSmall: CeylonTokens.borderRadiusSmall,
          borderRadiusMedium: CeylonTokens.borderRadiusMedium,
          borderRadiusLarge: CeylonTokens.borderRadiusLarge,
          shadowSmall: CeylonTokens.shadowSmall,
          shadowMedium: CeylonTokens.shadowMedium,
          shadowLarge: CeylonTokens.shadowLarge,
        ),
      ],
    );
  }

  /// Build text theme using Inter font family
  static TextTheme _buildTextTheme() {
    final interTextTheme = GoogleFonts.interTextTheme();
    // For fallback, we'll use Noto Sans in case of languages that Inter doesn't support
    // Uncomment if needed for specific language support
    // final notoSansTextTheme = GoogleFonts.notoSansTextTheme();
    
    return interTextTheme.copyWith(
      // Use notoSansTextTheme's displayLarge as fallback if needed
      displayLarge: interTextTheme.displayLarge,
      displayMedium: interTextTheme.displayMedium,
      displaySmall: interTextTheme.displaySmall,
      headlineLarge: interTextTheme.headlineLarge,
      headlineMedium: interTextTheme.headlineMedium,
      headlineSmall: interTextTheme.headlineSmall,
      titleLarge: interTextTheme.titleLarge,
      titleMedium: interTextTheme.titleMedium,
      titleSmall: interTextTheme.titleSmall,
      bodyLarge: interTextTheme.bodyLarge,
      bodyMedium: interTextTheme.bodyMedium,
      bodySmall: interTextTheme.bodySmall,
      labelLarge: interTextTheme.labelLarge,
      labelMedium: interTextTheme.labelMedium,
      labelSmall: interTextTheme.labelSmall,
    );
  }
}

/// Theme manager to handle theme mode changes
class ThemeManager extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode => _themeMode == ThemeMode.dark;
  
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}
