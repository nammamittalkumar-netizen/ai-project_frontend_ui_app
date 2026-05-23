import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:security_app/main.dart';

void main() {
  testWidgets('Security app shows dashboard and alerts tab', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: SecurityApp()));

    expect(find.text('Security Hub'), findsOneWidget);
    expect(find.text('Front Door'), findsOneWidget);
    expect(find.text('Parking Lot'), findsOneWidget);

    await tester.tap(find.text('Alerts'));
    await tester.pump();

    expect(find.text('Alerts'), findsWidgets);
    expect(find.text('Warehouse'), findsOneWidget);
  });
}
