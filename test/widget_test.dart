import 'package:flutter_test/flutter_test.dart';

import 'package:fixit_gh/main.dart';

void main() {
  testWidgets('App launches splash then navigates to welcome', (WidgetTester tester) async {
    await tester.pumpWidget(const FixitGhApp());

    expect(find.text('Fixit GH'), findsWidgets);
    expect(find.text('Find trusted artisans near you'), findsWidgets);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    expect(find.text('Continue as'), findsOneWidget);
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Artisan'), findsOneWidget);
    expect(find.text('Admin'), findsOneWidget);
  });
}
