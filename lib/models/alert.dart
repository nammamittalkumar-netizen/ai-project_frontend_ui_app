import 'package:flutter/material.dart';

enum AlertType { fire, smoke, liquidSpill, suspicious, fall }

class Alert {
  final String id;
  final AlertType type;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final String? clipUrl;

  const Alert({
    required this.id,
    required this.type,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    this.clipUrl,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id']?.toString() ?? '',
      type: _parseType(
        json['type']?.toString() ?? json['detection_type']?.toString(),
      ),
      cameraId: json['camera_id']?.toString() ?? '',
      cameraName: json['camera_name']?.toString() ?? 'Unknown Camera',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ??
          DateTime.now(),
      clipUrl: json['clip_url']?.toString() ?? json['video_url']?.toString(),
    );
  }

  static AlertType _parseType(String? value) {
    switch (value) {
      case 'fire':
        return AlertType.fire;
      case 'smoke':
        return AlertType.smoke;
      case 'liquid_spill':
        return AlertType.liquidSpill;
      case 'fall':
      case 'fall_down':
        return AlertType.fall;
      case 'suspicious_activity':
      case 'suspicious':
      default:
        return AlertType.suspicious;
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.fire:
        return 'Fire Detected';
      case AlertType.smoke:
        return 'Smoke Detected';
      case AlertType.liquidSpill:
        return 'Liquid Spill';
      case AlertType.suspicious:
        return 'Suspicious Activity';
      case AlertType.fall:
        return 'Person Fall';
    }
  }

  String get typeEmoji {
    switch (type) {
      case AlertType.fire:
        return 'Fire';
      case AlertType.smoke:
        return 'Smoke';
      case AlertType.liquidSpill:
        return 'Spill';
      case AlertType.suspicious:
        return 'Watch';
      case AlertType.fall:
        return 'Fall';
    }
  }

  String get typeLabelWithEmoji => typeLabel;

  Color get typeColor {
    switch (type) {
      case AlertType.fire:
        return Colors.orange;
      case AlertType.smoke:
        return Colors.blueGrey;
      case AlertType.liquidSpill:
        return Colors.lightBlue;
      case AlertType.suspicious:
        return Colors.purpleAccent;
      case AlertType.fall:
        return Colors.red;
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.fire:
        return Icons.local_fire_department_rounded;
      case AlertType.smoke:
        return Icons.cloud_rounded;
      case AlertType.liquidSpill:
        return Icons.water_drop_rounded;
      case AlertType.suspicious:
        return Icons.visibility_rounded;
      case AlertType.fall:
        return Icons.personal_injury_rounded;
    }
  }
}
