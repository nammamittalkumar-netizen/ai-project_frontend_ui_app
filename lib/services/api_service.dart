import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../models/camera.dart';

class ApiService {
  final String baseUrl;
  final String streamUrl;

  const ApiService({
    required this.baseUrl,
    required this.streamUrl,
  });

  Future<bool> checkHealth() async {
    if (baseUrl.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> && body['status'] == 'running';
    } catch (_) {
      return false;
    }
  }

  Future<List<Camera>> getCameras() async {
    if (baseUrl.isEmpty) {
      return [];
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/cameras'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);
      if (body is! List) {
        return [];
      }

      return body
          .whereType<Map<String, dynamic>>()
          .map(Camera.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<Alert>> getAlerts() async {
    if (baseUrl.isEmpty) {
      return [];
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/events?limit=100'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return [];
      }

      final body = jsonDecode(response.body);
      if (body is! List) {
        return [];
      }

      return body
          .whereType<Map<String, dynamic>>()
          .map(_alertFromServerJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String streamUrlForCamera(String cameraId) {
    return '$streamUrl/stream/$cameraId';
  }

  String websocketAlertsUrl() {
    final uri = Uri.parse(baseUrl);
    return Uri(
      scheme: uri.scheme == 'https' ? 'wss' : 'ws',
      host: uri.host,
      port: uri.hasPort ? uri.port : null,
      path: '/ws/alerts',
    ).toString();
  }

  Stream<Alert> watchAlerts() async* {
    if (baseUrl.isEmpty) {
      return;
    }

    while (true) {
      WebSocket? socket;
      try {
        socket = await WebSocket.connect(websocketAlertsUrl())
            .timeout(const Duration(seconds: 5));
        await for (final message in socket) {
          if (message is! String) {
            continue;
          }
          final body = jsonDecode(message);
          if (body is Map<String, dynamic> && body['type'] == 'alert') {
            final data = body['data'];
            if (data is Map<String, dynamic>) {
              yield _alertFromServerJson(data);
            }
          }
        }
      } catch (_) {
        await Future<void>.delayed(const Duration(seconds: 5));
      } finally {
        await socket?.close();
      }
    }
  }

  Future<ServerStatus?> getStatus() async {
    if (baseUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/status'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? ServerStatus.fromJson(body) : null;
    } catch (_) {
      return null;
    }
  }

  Future<AnalyticsSummary?> getAnalytics() async {
    if (baseUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/analytics'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic>
          ? AnalyticsSummary.fromJson(body)
          : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Alert>> searchAlerts(String query) async {
    if (baseUrl.isEmpty || query.trim().isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/api/search').replace(
        queryParameters: {'q': query.trim()},
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return [];
      }
      final body = jsonDecode(response.body);
      final results = body is Map<String, dynamic> ? body['results'] : null;
      if (results is! List) {
        return [];
      }
      return results
          .whereType<Map<String, dynamic>>()
          .map(_alertFromServerJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<RecordingItem>> getPlayback({
    required String cameraId,
    required DateTime date,
    required int rangeHours,
  }) async {
    if (baseUrl.isEmpty || cameraId.isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/api/playback').replace(
        queryParameters: {
          'camera_id': cameraId,
          'date': DateFormat('yyyy-MM-dd').format(date),
          'range_hours': '$rangeHours',
        },
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return [];
      }
      final body = jsonDecode(response.body);
      if (body is! List) {
        return [];
      }
      return body
          .whereType<Map<String, dynamic>>()
          .map((json) => RecordingItem.fromJson(json, baseUrl))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, bool>> getNotificationSettings() async {
    if (baseUrl.isEmpty) {
      return {};
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/settings'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return {};
      }
      final body = jsonDecode(response.body);
      final notifications =
          body is Map<String, dynamic> ? body['notifications'] : null;
      if (notifications is! Map<String, dynamic>) {
        return {};
      }
      return notifications.map((key, value) => MapEntry(key, value == true));
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, bool>> updateNotificationSettings(
    Map<String, bool> values,
  ) async {
    if (baseUrl.isEmpty) {
      return values;
    }

    try {
      final response = await http
          .put(
            Uri.parse('$baseUrl/api/settings/notifications'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(values),
          )
          .timeout(const Duration(seconds: 5));
      final body = jsonDecode(response.body);
      final notifications =
          body is Map<String, dynamic> ? body['notifications'] : null;
      if (notifications is Map<String, dynamic>) {
        return notifications.map((key, value) => MapEntry(key, value == true));
      }
    } catch (_) {}
    return values;
  }

  Future<Map<String, dynamic>?> getReport(String reportName) async {
    if (baseUrl.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/reports/$reportName'))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) {
        return null;
      }
      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> ? body : null;
    } catch (_) {
      return null;
    }
  }

  Alert _alertFromServerJson(Map<String, dynamic> json) {
    final id = json['id']?.toString() ?? json['event_id']?.toString() ?? '';
    return Alert.fromJson({
      ...json,
      'id': id,
      'type': json['type'] ?? json['detection_type'],
      'clip_url': json['clip_url'] ??
          (id.isEmpty ? null : '$baseUrl/api/events/$id/video'),
    });
  }
}

class ServerStatus {
  final int camerasTotal;
  final int camerasOnline;
  final int eventsToday;
  final int aiDetections;
  final double uptimePercent;

  const ServerStatus({
    required this.camerasTotal,
    required this.camerasOnline,
    required this.eventsToday,
    required this.aiDetections,
    required this.uptimePercent,
  });

  factory ServerStatus.fromJson(Map<String, dynamic> json) {
    return ServerStatus(
      camerasTotal: _asInt(json['cameras_total']),
      camerasOnline: _asInt(json['cameras_online']),
      eventsToday: _asInt(json['events_today']),
      aiDetections: _asInt(json['ai_detections']),
      uptimePercent: _asDouble(json['uptime_percent']),
    );
  }
}

class AnalyticsSummary {
  final int eventsTriggered;
  final int aiDetectionsTotal;
  final double avgDwellTimeHours;
  final List<TrendPoint> detectionTrends;
  final Map<String, int> topCategories;

  const AnalyticsSummary({
    required this.eventsTriggered,
    required this.aiDetectionsTotal,
    required this.avgDwellTimeHours,
    required this.detectionTrends,
    required this.topCategories,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> json) {
    final trends = json['detection_trends'];
    final categories = json['top_categories'];
    return AnalyticsSummary(
      eventsTriggered: _asInt(json['events_triggered']),
      aiDetectionsTotal: _asInt(json['ai_detections_total']),
      avgDwellTimeHours: _asDouble(json['avg_dwell_time_hours']),
      detectionTrends: trends is List
          ? trends
              .whereType<Map<String, dynamic>>()
              .map(TrendPoint.fromJson)
              .toList()
          : const [],
      topCategories: categories is Map<String, dynamic>
          ? categories.map((key, value) => MapEntry(key, _asInt(value)))
          : const {},
    );
  }
}

class TrendPoint {
  final String day;
  final int count;

  const TrendPoint({required this.day, required this.count});

  factory TrendPoint.fromJson(Map<String, dynamic> json) {
    return TrendPoint(
      day: json['day']?.toString() ?? '',
      count: _asInt(json['count']),
    );
  }
}

class RecordingItem {
  final int id;
  final String cameraId;
  final String cameraName;
  final DateTime startTime;
  final double durationSeconds;
  final String videoUrl;

  const RecordingItem({
    required this.id,
    required this.cameraId,
    required this.cameraName,
    required this.startTime,
    required this.durationSeconds,
    required this.videoUrl,
  });

  factory RecordingItem.fromJson(Map<String, dynamic> json, String baseUrl) {
    final id = _asInt(json['id']);
    return RecordingItem(
      id: id,
      cameraId: json['camera_id']?.toString() ?? '',
      cameraName: json['camera_name']?.toString() ?? '',
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? '') ??
          DateTime.now(),
      durationSeconds: _asDouble(json['duration_seconds']),
      videoUrl: '$baseUrl/api/playback/video/$id',
    );
  }
}

int _asInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.round();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _asDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '') ?? 0;
}
