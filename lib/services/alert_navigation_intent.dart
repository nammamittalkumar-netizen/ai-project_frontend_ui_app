import 'package:shared_preferences/shared_preferences.dart';

const kAlertNavigationIntentKey = 'pending_alert_navigation';
const kAlertNavigationAi = 'alerts:ai';
const kAlertNavigationSystem = 'alerts:system';

String alertNavigationPayloadForType(String type) {
  return switch (type) {
    'camera_offline' ||
    'camera_online' ||
    'storage_warning' ||
    'storage_critical' =>
      kAlertNavigationSystem,
    _ => kAlertNavigationAi,
  };
}

Future<void> savePendingAlertNavigation(String payload) async {
  if (payload != kAlertNavigationAi && payload != kAlertNavigationSystem) {
    return;
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.setString(kAlertNavigationIntentKey, payload);
}

Future<String?> takePendingAlertNavigation() async {
  final prefs = await SharedPreferences.getInstance();
  final payload = prefs.getString(kAlertNavigationIntentKey);
  await prefs.remove(kAlertNavigationIntentKey);
  return payload;
}
