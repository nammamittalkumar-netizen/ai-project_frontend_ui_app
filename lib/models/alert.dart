import 'package:flutter/material.dart';

enum AlertType {
  fire,
  smoke,
  liquidSpill,
  suspicious,
  fall,
  cameraOffline,
  cameraOnline,
  storageWarning,
  storageCritical,
}

class Alert {
  final String id;
  final AlertType type;
  final String cameraId;
  final String cameraName;
  final DateTime timestamp;
  final String? clipUrl;
  final String? snapshotUrl;
  final double confidence;

  const Alert({
    required this.id,
    required this.type,
    required this.cameraId,
    required this.cameraName,
    required this.timestamp,
    this.clipUrl,
    this.snapshotUrl,
    this.confidence = 0,
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
      snapshotUrl: json['snapshot_url']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
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
      case 'camera_offline':
        return AlertType.cameraOffline;
      case 'camera_online':
        return AlertType.cameraOnline;
      case 'storage_warning':
        return AlertType.storageWarning;
      case 'storage_critical':
        return AlertType.storageCritical;
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
      case AlertType.cameraOffline:
        return 'Camera Offline';
      case AlertType.cameraOnline:
        return 'Camera Online';
      case AlertType.storageWarning:
        return 'Storage Warning';
      case AlertType.storageCritical:
        return 'Storage Critical';
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
      case AlertType.cameraOffline:
        return 'Offline';
      case AlertType.cameraOnline:
        return 'Online';
      case AlertType.storageWarning:
        return 'Storage';
      case AlertType.storageCritical:
        return 'Storage';
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
      case AlertType.cameraOffline:
        return Colors.deepOrange;
      case AlertType.cameraOnline:
        return Colors.green;
      case AlertType.storageWarning:
        return Colors.amber;
      case AlertType.storageCritical:
        return Colors.redAccent;
    }
  }

  bool get isDetection =>
      type == AlertType.fire ||
      type == AlertType.smoke ||
      type == AlertType.liquidSpill ||
      type == AlertType.suspicious ||
      type == AlertType.fall;

  bool get isSystem => !isDetection;

  String get displaySource {
    if (isDetection) {
      return cameraName.trim().isEmpty ? 'Unknown Camera' : cameraName;
    }

    switch (type) {
      case AlertType.storageWarning:
      case AlertType.storageCritical:
        return 'Storage Monitor';
      case AlertType.cameraOffline:
      case AlertType.cameraOnline:
        return 'Camera Health';
      case AlertType.fire:
      case AlertType.smoke:
      case AlertType.liquidSpill:
      case AlertType.suspicious:
      case AlertType.fall:
        return 'System';
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
      case AlertType.cameraOffline:
        return Icons.videocam_off_rounded;
      case AlertType.cameraOnline:
        return Icons.videocam_rounded;
      case AlertType.storageWarning:
        return Icons.storage_rounded;
      case AlertType.storageCritical:
        return Icons.sd_storage_rounded;
    }
  }
}
