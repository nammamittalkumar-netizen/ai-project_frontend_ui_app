import 'package:flutter/material.dart';

enum AlertType { fire, smoke, liquidSpill, suspicious, fall }

class Alert {
  final String id;
  final AlertType type;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final String? clipUrl;   // 5-sec video clip URL

  Alert({
    required this.id,
    required this.type,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    this.clipUrl,
  });

  factory Alert.fromJson(Map<String, dynamic> json) => Alert(
    id:         json['id'],
    type:       _parseType(json['type']),
    cameraId:   json['camera_id'],
    cameraName: json['camera_name'],
    timestamp:  DateTime.parse(json['timestamp']),
    clipUrl:    json['clip_url'],
  );

  static AlertType _parseType(String t) {
    switch (t) {
      case 'fire':        return AlertType.fire;
      case 'smoke':       return AlertType.smoke;
      case 'liquid_spill':return AlertType.liquidSpill;
      case 'suspicious':  return AlertType.suspicious;
      case 'fall':        return AlertType.fall;
      default:            return AlertType.suspicious;
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.fire:        return '🔥 Fire Detected';
      case AlertType.smoke:       return '💨 Smoke Detected';
      case AlertType.liquidSpill: return '💧 Liquid Spill';
      case AlertType.suspicious:  return '👁️ Suspicious Activity';
      case AlertType.fall:        return '🧍 Person Fall';
    }
  }

  Color get typeColor {
    switch (type) {
      case AlertType.fire:        return Colors.orange;
      case AlertType.smoke:       return Colors.grey;
      case AlertType.liquidSpill: return Colors.blue;
      case AlertType.suspicious:  return Colors.purple;
      case AlertType.fall:        return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.fire:        return Icons.local_fire_department;
      case AlertType.smoke:       return Icons.cloud;
      case AlertType.liquidSpill: return Icons.water_drop;
      case AlertType.suspicious:  return Icons.visibility;
      case AlertType.fall:        return Icons.personal_injury;
    }
  }
}