import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/alert.dart';
import '../models/camera.dart';

class ApiService {
  final String baseUrl;
  final String streamUrl;

  ApiService({required this.baseUrl, required this.streamUrl});

  // Fetch list of cameras
  Future<List<Camera>> getCameras() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/cameras'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Camera.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Fetch latest alerts
  Future<List<Alert>> getAlerts() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/alerts'))
          .timeout(const Duration(seconds: 5));
      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        return data.map((e) => Alert.fromJson(e)).toList();
      }
    } catch (_) {}
    return [];
  }

  // Stream URL for a camera
  String streamUrlForCamera(String cameraId) =>
      '$streamUrl/stream/$cameraId';
}