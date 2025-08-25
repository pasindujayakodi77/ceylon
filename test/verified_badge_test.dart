import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ceylon/design_system/app_theme.dart';
import 'package:ceylon/core/l10n/locale_controller.dart';
import 'package:ceylon/core/booking/widgets/verified_badge.dart';

void main() {
  testWidgets('VerifiedBadge shows label and opens verification sheet on tap', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeManager()),
          ChangeNotifierProvider(create: (_) => LocaleController()),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Center(
              child: VerifiedBadge(
                businessId: 'test-business',
                label: 'Verified',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Verified'), findsOneWidget);

    // Tap the badge - should open bottom sheet with 'Step 1 — Owner details'
    await tester.tap(find.byType(VerifiedBadge));
    await tester.pumpAndSettle();

    expect(find.textContaining('Step 1'), findsOneWidget);
  });
}
