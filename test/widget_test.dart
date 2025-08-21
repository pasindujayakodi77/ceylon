// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/core/l10n/locale_controller.dart';

import 'package:ceylon/main.dart';

void main() {
  testWidgets('Ceylon app displays welcome message', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
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

    // Verify that our app displays the welcome message.
    expect(find.text('🧭 Welcome to CEYLON App'), findsOneWidget);
  });
}
