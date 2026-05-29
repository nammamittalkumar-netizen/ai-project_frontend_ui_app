import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'alert_navigation_intent.dart';
import 'alert_review_state.dart';

// SharedPreferences key shared between background service and main app.
// Both sides read/write this so they don't double-notify for the same alert.
const _kServiceChannelId = 'security_service';
const _kAlertChannelId = 'security_alerts';
const _kServiceNotifId = 999;

Future<void> initBackgroundService() async {
  final service = FlutterBackgroundService();

  // Low-importance channel for the persistent "monitoring" notification.
  final plugin = FlutterLocalNotificationsPlugin();
  await plugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(
        const AndroidNotificationChannel(
          _kServiceChannelId,
          'Security Monitoring',
          description: 'Keeps Security Hub running in the background',
          importance: Importance.low,
          playSound: false,
          enableVibration: false,
        ),
      );

  // configure() must always be called to register the onStart callback,
  // even if the service is already running (the callback lives in this isolate).
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: _onServiceStart,
      autoStart: true,
      isForegroundMode: true,
      notificationChannelId: _kServiceChannelId,
      initialNotificationTitle: 'Security Hub',
      initialNotificationContent: 'Monitoring for alerts…',
      foregroundServiceNotificationId: _kServiceNotifId,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(
      autoStart: true,
      onForeground: _onServiceStart,
      onBackground: _onIosBackground,
    ),
  );

  // Only call startService() if the service is NOT already running.
  // Calling it on an already-running service can reset the isolate and
  // cause a gap in polling — which is exactly the "background disconnect" bug.
  final alreadyRunning = await service.isRunning();
  if (!alreadyRunning) {
    service.startService();
  }
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();
  return true;
}

@pragma('vm:entry-point')
void _onServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final plugin = FlutterLocalNotificationsPlugin();
  await plugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ),
  );

  service.on('stop').listen((_) => service.stopSelf());

  // Poll every 10 seconds regardless of whether the main app is running.
  // Errors inside _pollAndNotify are already caught; wrapping with catchError
  // here ensures a crash in one tick never kills the timer.
  Timer.periodic(const Duration(seconds: 10), (_) {
    _pollAndNotify(plugin).catchError((_) {});
  });
}

Future<void> _pollAndNotify(FlutterLocalNotificationsPlugin plugin) async {
  try {
    final prefs = await SharedPreferences.getInstance();

    if (prefs.getBool('demo_mode') ?? false) return;

    final ip = prefs.getString('server_ip');
    if (ip == null || ip.trim().isEmpty) return;

    final apiPort = prefs.getInt('api_port') ?? 8000;
    final apiUrl = 'http://${ip.trim()}:$apiPort';

    // Read the last-seen ID — shared with the main app.
    final lastId = prefs.getString(kBgLastAlertId) ?? '';

    final today = DateTime.now();
    final dateFrom = DateTime(today.year, today.month, today.day);
    final uri = Uri.parse('$apiUrl/api/events').replace(
      queryParameters: {
        'limit': '1',
        'date_from': dateFrom.toIso8601String(),
      },
    );
    final response = await http.get(
      uri,
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode != 200) return;

    final dynamic body = jsonDecode(response.body);
    final List<dynamic> list = body is List
        ? body
        : body is Map
            ? (body['alerts'] as List? ?? body['events'] as List? ?? [])
            : [];
    if (list.isEmpty) return;

    final latest = list.first as Map<String, dynamic>;
    final latestId = '${latest['id'] ?? latest['event_id'] ?? ''}';
    if (latestId.isEmpty || latestId == lastId) return;

    // Mark as seen BEFORE showing the notification so the main app won't
    // show a duplicate popup when it comes to the foreground.
    await prefs.setString(kBgLastAlertId, latestId);

    final type = '${latest['type'] ?? latest['detection_type'] ?? ''}';
    final camera = '${latest['camera_name'] ?? ''}';

    await plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      _titleForType(type),
      camera.isNotEmpty ? camera : 'New security alert',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _kAlertChannelId,
          'Security Alerts',
          channelDescription: 'Real-time alerts from your security cameras',
          importance: Importance.max,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: alertNavigationPayloadForType(type),
    );
  } catch (_) {}
}

String _titleForType(String type) {
  return switch (type) {
    'fire_detected' => '🔥 Fire Detected',
    'smoke_detected' => '💨 Smoke Detected',
    'liquid_spill' => '💧 Liquid Spill',
    'suspicious_activity' => '👁 Suspicious Activity',
    'person_fall' => '🚨 Person Fall Detected',
    'camera_offline' => '📷 Camera Offline',
    'camera_online' => '📷 Camera Back Online',
    'storage_warning' => '💾 Storage Warning',
    'storage_critical' => '⚠️ Storage Critical',
    _ => '🔔 Security Alert',
  };
}
