import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/main.dart';

void main() {
  testWidgets('shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeManager()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
        ],
        child: const MyApp(
          home: Center(child: Text('🧭 Welcome to CEYLON App')),
        ),
      ),
    );
    expect(find.text('🧭 Welcome to CEYLON App'), findsOneWidget);
  });
}
