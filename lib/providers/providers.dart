import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/alert.dart';
import '../models/camera.dart';
import '../services/api_service.dart';

// ── Settings state (server IPs) ──────────────────────────
class ServerConfig {
  final String apiUrl;
  final String streamUrl;
  ServerConfig({
    this.apiUrl    = 'http://192.168.1.100:8000',
    this.streamUrl = 'http://192.168.1.100:8888',
  });
  ServerConfig copyWith({String? apiUrl, String? streamUrl}) => ServerConfig(
    apiUrl:    apiUrl    ?? this.apiUrl,
    streamUrl: streamUrl ?? this.streamUrl,
  );
}

final serverConfigProvider = StateNotifierProvider<ServerConfigNotifier, ServerConfig>(
  (ref) => ServerConfigNotifier(),
);

class ServerConfigNotifier extends StateNotifier<ServerConfig> {
  ServerConfigNotifier() : super(ServerConfig());
  void update({String? apiUrl, String? streamUrl}) {
    state = state.copyWith(apiUrl: apiUrl, streamUrl: streamUrl);
  }
}

// ── ApiService ───────────────────────────────────────────
final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(serverConfigProvider);
  return ApiService(baseUrl: config.apiUrl, streamUrl: config.streamUrl);
});

// ── Cameras (fetched once + refresh) ─────────────────────
final camerasProvider = FutureProvider<List<Camera>>((ref) async {
  return ref.watch(apiServiceProvider).getCameras();
});

// ── Alerts polling every 3 seconds ───────────────────────
final alertsProvider = StreamProvider<List<Alert>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return Stream.periodic(const Duration(seconds: 3))
      .asyncMap((_) => api.getAlerts());
});

// ── Track last seen alert ID to detect NEW alerts ─────────
final lastAlertIdProvider = StateProvider<String?>((ref) => null);