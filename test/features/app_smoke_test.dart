import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:ceylon/main.dart';

void main() {
  testWidgets('shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MyApp(
        home: const Center(child: const Text('🧭 Welcome to CEYLON App')),
      ),
    );
    expect(find.text('🧭 Welcome to CEYLON App'), findsOneWidget);
  });
}
