import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'alert_navigation_intent.dart';

class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static final _tapController = StreamController<String>.broadcast();
  static bool _initialized = false;

  static Stream<String> get notificationTaps => _tapController.stream;

  static Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _handleNotificationResponse,
    );

    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final launchPayload = launchDetails?.notificationResponse?.payload;
    if (launchDetails?.didNotificationLaunchApp == true &&
        launchPayload != null) {
      await _handlePayload(launchPayload);
    }

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'security_alerts',
            'Security Alerts',
            description: 'Real-time alerts from your security cameras',
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );

    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    _initialized = true;
  }

  static Future<void> showAlert({
    required String title,
    required String body,
    String payload = kAlertNavigationAi,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'security_alerts',
      'Security Alerts',
      channelDescription: 'Real-time alerts from your security cameras',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      ticker: 'Security Alert',
      icon: '@mipmap/ic_launcher',
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  static void _handleNotificationResponse(NotificationResponse response) {
    final payload = response.payload;
    if (payload == null) return;
    _handlePayload(payload);
  }

  static Future<void> _handlePayload(String payload) async {
    if (payload != kAlertNavigationAi && payload != kAlertNavigationSystem) {
      return;
    }

    // If the app is alive and a listener is attached, hand the tap off live and
    // do NOT persist — otherwise a leftover intent would hijack the next launch.
    if (!_tapController.isClosed && _tapController.hasListener) {
      _tapController.add(payload);
      return;
    }

    // Cold-launch path: no live listener yet, so stash the intent for initState.
    await savePendingAlertNavigation(payload);
  }
}
