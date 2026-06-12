import 'package:businesscard/app/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('shows the login page', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: BusinessCardApp()));

    expect(find.text('Business Card'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
