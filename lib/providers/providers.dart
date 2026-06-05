import 'dart:async';

import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';
import '../models/camera.dart';
import '../services/api_service.dart';

const int defaultApiPort = 8000;
const int defaultStreamPort = 8888;
const int defaultAccentColorValue = 0xFFF44336;

/// Keys for the "last known server" — these survive an explicit Disconnect so
/// the SetupScreen can pre-fill the fields and auto-reconnect.
const _kLastIp = 'last_server_ip';
const _kLastApiPort = 'last_api_port';
const _kLastStreamPort = 'last_stream_port';

enum ConnectionStatus { connected, reconnecting, notConfigured }

class AppAccentColor {
  final String name;
  final int value;

  const AppAccentColor({
    required this.name,
    required this.value,
  });
}

const appAccentColors = [
  AppAccentColor(name: 'Red', value: 0xFFF44336),
  AppAccentColor(name: 'Blue', value: 0xFF2196F3),
  AppAccentColor(name: 'Green', value: 0xFF4CAF50),
  AppAccentColor(name: 'Orange', value: 0xFFFF9800),
  AppAccentColor(name: 'Purple', value: 0xFF9C27B0),
  AppAccentColor(name: 'Teal', value: 0xFF009688),
];

class ServerConfig {
  final String apiUrl;
  final String streamUrl;
  final bool isDemo;

  const ServerConfig({
    required this.apiUrl,
    required this.streamUrl,
    this.isDemo = false,
  });

  factory ServerConfig.empty() => const ServerConfig(apiUrl: '', streamUrl: '');

  factory ServerConfig.demo() {
    return const ServerConfig(
      apiUrl: 'demo://api',
      streamUrl: 'demo://stream',
      isDemo: true,
    );
  }

  factory ServerConfig.fromParts({
    required String ip,
    required int apiPort,
    required int streamPort,
  }) {
    final trimmedIp = ip.trim();
    return ServerConfig(
      apiUrl: 'http://$trimmedIp:$apiPort',
      streamUrl: 'http://$trimmedIp:$streamPort',
    );
  }

  bool get isConfigured =>
      isDemo || (apiUrl.isNotEmpty && streamUrl.isNotEmpty);

  String get serverIp => isDemo ? 'Demo Mode' : _hostFromUrl(apiUrl);

  int get apiPort =>
      isDemo ? defaultApiPort : _portFromUrl(apiUrl, defaultApiPort);

  int get streamPort =>
      isDemo ? defaultStreamPort : _portFromUrl(streamUrl, defaultStreamPort);

  ServerConfig copyWith({String? apiUrl, String? streamUrl, bool? isDemo}) {
    return ServerConfig(
      apiUrl: apiUrl ?? this.apiUrl,
      streamUrl: streamUrl ?? this.streamUrl,
      isDemo: isDemo ?? this.isDemo,
    );
  }

  static String _hostFromUrl(String value) {
    return Uri.tryParse(value)?.host ?? '';
  }

  static int _portFromUrl(String value, int fallback) {
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasPort) {
      return fallback;
    }
    return uri.port;
  }
}

enum ServerConnectionState {
  online,
  offline,
}

class ServerConnection {
  final ServerConnectionState state;
  final DateTime checkedAt;

  const ServerConnection({
    required this.state,
    required this.checkedAt,
  });

  bool get isOnline => state == ServerConnectionState.online;
}

final initialServerConfigProvider = Provider<ServerConfig?>((ref) => null);

final serverConfigProvider =
    StateNotifierProvider<ServerConfigNotifier, ServerConfig>((ref) {
  return ServerConfigNotifier(ref.watch(initialServerConfigProvider));
});

class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  ServerConfigNotifier(ServerConfig? initial)
      : super(initial ?? ServerConfig.empty()) {
    loadSavedConfig();
  }

  Future<void> loadSavedConfig() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool('demo_mode') ?? false) {
      state = ServerConfig.demo();
      return;
    }

    final ip = prefs.getString('server_ip');
    if (ip == null || ip.trim().isEmpty) {
      return;
    }

    state = ServerConfig.fromParts(
      ip: ip,
      apiPort: prefs.getInt('api_port') ?? defaultApiPort,
      streamPort: prefs.getInt('stream_port') ?? defaultStreamPort,
    );
  }

  Future<void> save({
    required String ip,
    required int apiPort,
    required int streamPort,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode', false);
    await prefs.setString('server_ip', ip.trim());
    await prefs.setInt('api_port', apiPort);
    await prefs.setInt('stream_port', streamPort);

    // Persist last-known IP separately — NOT cleared on explicit Disconnect,
    // so the SetupScreen can auto-fill and auto-reconnect later.
    await prefs.setString(_kLastIp, ip.trim());
    await prefs.setInt(_kLastApiPort, apiPort);
    await prefs.setInt(_kLastStreamPort, streamPort);

    state = ServerConfig.fromParts(
      ip: ip,
      apiPort: apiPort,
      streamPort: streamPort,
    );
  }

  Future<void> useDemoMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('demo_mode', true);
    await prefs.remove('server_ip');
    await prefs.remove('api_port');
    await prefs.remove('stream_port');
    state = ServerConfig.demo();
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('demo_mode');
    await prefs.remove('server_ip');
    await prefs.remove('api_port');
    await prefs.remove('stream_port');
    state = ServerConfig.empty();
  }
}

final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(serverConfigProvider);
  return ApiService(baseUrl: config.apiUrl, streamUrl: config.streamUrl);
});

final serverConnectionProvider = StreamProvider<ServerConnection>((ref) async* {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured) {
    yield ServerConnection(
      state: ServerConnectionState.offline,
      checkedAt: DateTime.now(),
    );
    return;
  }

  if (config.isDemo) {
    yield ServerConnection(
      state: ServerConnectionState.online,
      checkedAt: DateTime.now(),
    );
    return;
  }

  final api = ref.watch(apiServiceProvider);
  while (true) {
    final online = await api.checkHealth();
    yield ServerConnection(
      state:
          online ? ServerConnectionState.online : ServerConnectionState.offline,
      checkedAt: DateTime.now(),
    );
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

final camerasProvider = StreamProvider<List<Camera>>((ref) async* {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured) {
    yield [];
    return;
  }
  if (config.isDemo) {
    yield _demoCameras;
    return;
  }

  final api = ref.watch(apiServiceProvider);
  while (true) {
    yield await api.getCameras();
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

final statusProvider = StreamProvider<ServerStatus?>((ref) async* {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured || config.isDemo) {
    yield null;
    return;
  }

  final api = ref.watch(apiServiceProvider);
  while (true) {
    yield await api.getStatus();
    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

final analyticsProvider = FutureProvider<AnalyticsSummary?>((ref) async {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured || config.isDemo) {
    return null;
  }
  return ref.watch(apiServiceProvider).getAnalytics();
});

final notificationSettingsProvider =
    FutureProvider<Map<String, bool>>((ref) async {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured || config.isDemo) {
    return const {
      // PPE violations alert by default; compliance detections stay silent.
      'no_helmet': true,
      'no_vest': true,
      'no_gloves': true,
      'no_goggles': true,
      'no_face_mask': true,
      'no_safety_shoes': true,
      'no_harness': true,
      'no_ear_protection': true,
      'helmet': false,
      'safety_vest': false,
      'gloves': false,
      'goggles': false,
      'face_mask': false,
      'safety_shoes': false,
      'harness': false,
      'ear_protection': false,
      'protective_suit': false,
      'apron': false,
      'face_shield': false,
      'camera_offline': true,
      'camera_online': true,
      'storage_warning': true,
      'storage_critical': true,
    };
  }
  return ref.watch(apiServiceProvider).getNotificationSettings();
});

final storageStatusProvider = StreamProvider<StorageStatus?>((ref) async* {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured || config.isDemo) {
    yield null;
    return;
  }

  final api = ref.watch(apiServiceProvider);
  yield await api.getStorageStatus();
  await for (final storage in api.watchStorageStatus()) {
    yield storage;
  }
});

final alertsProvider = StreamProvider<List<Alert>>((ref) async* {
  final config = ref.watch(serverConfigProvider);
  if (!config.isConfigured) {
    yield [];
    return;
  }
  if (config.isDemo) {
    while (true) {
      yield _demoAlerts();
      await Future<void>.delayed(const Duration(seconds: 3));
    }
  }

  final api = ref.watch(apiServiceProvider);
  while (true) {
    var alerts = await api.getAlerts();
    yield alerts;
    try {
      await for (final alert in api.watchAlerts()) {
        alerts = [
          alert,
          ...alerts.where((item) => item.id != alert.id),
        ].take(100).toList();
        yield alerts;
      }
    } catch (_) {}

    await Future<void>.delayed(const Duration(seconds: 5));
  }
});

final lastAlertIdProvider = StateProvider<String?>((ref) => null);

final reviewedAlertIdsProvider = StateProvider<Set<String>>((ref) => const {});

final accentColorProvider =
    StateNotifierProvider<AccentColorNotifier, int>((ref) {
  return AccentColorNotifier();
});

class AccentColorNotifier extends StateNotifier<int> {
  AccentColorNotifier() : super(defaultAccentColorValue) {
    loadSavedColor();
  }

  Future<void> loadSavedColor() async {
    final prefs = await SharedPreferences.getInstance();
    final savedColor = prefs.getInt('accent_color');
    if (savedColor == null) {
      return;
    }
    state = savedColor;
  }

  Future<void> save(int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', value);
    state = value;
  }
}

const _demoCameras = [
  Camera(
    id: 'demo-front-door',
    name: 'Front Door',
    location: 'Entrance',
    isOnline: true,
  ),
  Camera(
    id: 'demo-parking',
    name: 'Parking Lot',
    location: 'Outside',
    isOnline: true,
  ),
  Camera(
    id: 'demo-warehouse',
    name: 'Warehouse',
    location: 'Storage',
    isOnline: true,
  ),
  Camera(
    id: 'demo-back-gate',
    name: 'Back Gate',
    location: 'Rear',
    isOnline: false,
  ),
];

// ── Connection-status provider ─────────────────────────────────────────────
//
// Continuously polls the server and emits [ConnectionStatus].
// Screens can watch this to show a reconnecting banner when the link drops.

final connectionStatusProvider = StreamProvider<ConnectionStatus>((ref) async* {
  final config = ref.watch(serverConfigProvider);

  if (!config.isConfigured || config.isDemo) {
    yield ConnectionStatus.notConfigured;
    return;
  }

  final api = ref.watch(apiServiceProvider);
  while (true) {
    final healthy = await api.checkHealth();
    yield healthy ? ConnectionStatus.connected : ConnectionStatus.reconnecting;
    // Poll more aggressively when offline so the UI recovers quickly.
    await Future<void>.delayed(Duration(seconds: healthy ? 10 : 5));
  }
});

// ── Last-known IP helper ───────────────────────────────────────────────────
//
// Returns {ip, apiPort, streamPort} from prefs if the user has connected at
// least once. Returns null if storage was fully wiped (fresh install or
// manual app-data clear).

Future<Map<String, Object>?> loadLastKnownServer() async {
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString(_kLastIp);
  if (ip == null || ip.trim().isEmpty) return null;
  return {
    'ip': ip.trim(),
    'apiPort': prefs.getInt(_kLastApiPort) ?? defaultApiPort,
    'streamPort': prefs.getInt(_kLastStreamPort) ?? defaultStreamPort,
  };
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.dark) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool('dark_mode');
    if (saved != null) {
      state = saved ? ThemeMode.dark : ThemeMode.light;
    }
  }

  Future<void> toggle() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = state != ThemeMode.dark;
    await prefs.setBool('dark_mode', isDark);
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

List<Alert> _demoAlerts() {
  final now = DateTime.now();
  return [
    Alert(
      id: 'demo-no-helmet',
      type: AlertType.noHelmet,
      cameraId: 'demo-warehouse',
      cameraName: 'Warehouse',
      timestamp: now.subtract(const Duration(minutes: 2)),
      confidence: 0.96,
    ),
    Alert(
      id: 'demo-no-vest',
      type: AlertType.noVest,
      cameraId: 'demo-front-door',
      cameraName: 'Entrance Gate',
      timestamp: now.subtract(const Duration(minutes: 12)),
      confidence: 0.91,
    ),
    Alert(
      id: 'demo-no-gloves',
      type: AlertType.noGloves,
      cameraId: 'demo-workshop',
      cameraName: 'Workshop Floor',
      timestamp: now.subtract(const Duration(hours: 1)),
      confidence: 0.88,
    ),
  ];
}
