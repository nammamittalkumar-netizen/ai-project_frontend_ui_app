import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:security_app/main.dart';

void main() {
  testWidgets('Security app starts on setup when not configured', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SecurityApp(hasConfig: false),
      ),
    );

    expect(find.text('Security Hub'), findsOneWidget);
    expect(find.text('Connect'), findsOneWidget);
    expect(find.text('Mini PC IP address'), findsOneWidget);
  });
}
