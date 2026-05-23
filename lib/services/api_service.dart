import 'dart:convert';

import 'package:http/http.dart' as http;

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
          .get(Uri.parse('$baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        return false;
      }

      final body = jsonDecode(response.body);
      return body is Map<String, dynamic> && body['status'] == 'ok';
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
          .get(Uri.parse('$baseUrl/cameras'))
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
          .get(Uri.parse('$baseUrl/alerts'))
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
          .map(Alert.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  String streamUrlForCamera(String cameraId) {
    return '$streamUrl/stream/$cameraId';
  }
}
