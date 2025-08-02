import 'package:flutter_test/flutter_test.dart';
import 'package:ceylon/main.dart';

void main() {
  testWidgets('shows welcome message', (WidgetTester tester) async {
    await tester.pumpWidget(const CeylonApp());
    expect(find.text('🧭 Welcome to CEYLON App'), findsOneWidget);
  });
}
