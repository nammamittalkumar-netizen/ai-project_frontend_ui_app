import 'package:flutter_test/flutter_test.dart';
import 'package:security_app/services/alert_navigation_intent.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('alertNavigationPayloadForType routes system alerts to system section',
      () {
    expect(
      alertNavigationPayloadForType('camera_offline'),
      kAlertNavigationSystem,
    );
    expect(
      alertNavigationPayloadForType('storage_critical'),
      kAlertNavigationSystem,
    );
  });

  test('alertNavigationPayloadForType routes detections to AI section', () {
    expect(alertNavigationPayloadForType('fire'), kAlertNavigationAi);
    expect(
      alertNavigationPayloadForType('suspicious_activity'),
      kAlertNavigationAi,
    );
  });

  test('takePendingAlertNavigation returns and clears saved destination',
      () async {
    SharedPreferences.setMockInitialValues({});

    await savePendingAlertNavigation(kAlertNavigationSystem);

    expect(await takePendingAlertNavigation(), kAlertNavigationSystem);
    expect(await takePendingAlertNavigation(), isNull);
  });
}
