import 'package:flutter/material.dart';

enum AlertType {
  // ── PPE violations (raise alerts) ─────────────────────────────
  noHelmet,
  noVest,
  noGloves,
  noGoggles,
  noFaceMask,
  noSafetyShoes,
  noHarness,
  noEarProtection,
  // ── PPE compliance (tracked, informational) ───────────────────
  helmet,
  safetyVest,
  gloves,
  goggles,
  faceMask,
  safetyShoes,
  harness,
  earProtection,
  protectiveSuit,
  apron,
  faceShield,
  // ── System ────────────────────────────────────────────────────
  cameraOffline,
  cameraOnline,
  storageWarning,
  storageCritical,
}

/// PPE violation types — these are the alert-worthy detections.
const Set<AlertType> _violationTypes = {
  AlertType.noHelmet,
  AlertType.noVest,
  AlertType.noGloves,
  AlertType.noGoggles,
  AlertType.noFaceMask,
  AlertType.noSafetyShoes,
  AlertType.noHarness,
  AlertType.noEarProtection,
};

/// PPE compliance types — tracked but not alert-worthy.
const Set<AlertType> _complianceTypes = {
  AlertType.helmet,
  AlertType.safetyVest,
  AlertType.gloves,
  AlertType.goggles,
  AlertType.faceMask,
  AlertType.safetyShoes,
  AlertType.harness,
  AlertType.earProtection,
  AlertType.protectiveSuit,
  AlertType.apron,
  AlertType.faceShield,
};

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
      case 'no_helmet':
        return AlertType.noHelmet;
      case 'no_vest':
      case 'no_safety_vest':
        return AlertType.noVest;
      case 'no_gloves':
        return AlertType.noGloves;
      case 'no_goggles':
        return AlertType.noGoggles;
      case 'no_face_mask':
      case 'no_mask':
        return AlertType.noFaceMask;
      case 'no_safety_shoes':
      case 'no_shoes':
        return AlertType.noSafetyShoes;
      case 'no_harness':
        return AlertType.noHarness;
      case 'no_ear_protection':
        return AlertType.noEarProtection;
      case 'helmet':
        return AlertType.helmet;
      case 'safety_vest':
      case 'vest':
        return AlertType.safetyVest;
      case 'gloves':
        return AlertType.gloves;
      case 'goggles':
        return AlertType.goggles;
      case 'face_mask':
      case 'mask':
        return AlertType.faceMask;
      case 'safety_shoes':
        return AlertType.safetyShoes;
      case 'harness':
        return AlertType.harness;
      case 'ear_protection':
        return AlertType.earProtection;
      case 'protective_suit':
        return AlertType.protectiveSuit;
      case 'apron':
        return AlertType.apron;
      case 'face_shield':
        return AlertType.faceShield;
      case 'camera_offline':
        return AlertType.cameraOffline;
      case 'camera_online':
        return AlertType.cameraOnline;
      case 'storage_warning':
        return AlertType.storageWarning;
      case 'storage_critical':
        return AlertType.storageCritical;
      default:
        return AlertType.noHelmet;
    }
  }

  String get typeLabel {
    switch (type) {
      case AlertType.noHelmet:
        return 'No Helmet';
      case AlertType.noVest:
        return 'No Safety Vest';
      case AlertType.noGloves:
        return 'No Gloves';
      case AlertType.noGoggles:
        return 'No Goggles';
      case AlertType.noFaceMask:
        return 'No Face Mask';
      case AlertType.noSafetyShoes:
        return 'No Safety Shoes';
      case AlertType.noHarness:
        return 'No Harness';
      case AlertType.noEarProtection:
        return 'No Ear Protection';
      case AlertType.helmet:
        return 'Helmet';
      case AlertType.safetyVest:
        return 'Safety Vest';
      case AlertType.gloves:
        return 'Gloves';
      case AlertType.goggles:
        return 'Goggles';
      case AlertType.faceMask:
        return 'Face Mask';
      case AlertType.safetyShoes:
        return 'Safety Shoes';
      case AlertType.harness:
        return 'Harness';
      case AlertType.earProtection:
        return 'Ear Protection';
      case AlertType.protectiveSuit:
        return 'Protective Suit';
      case AlertType.apron:
        return 'Apron';
      case AlertType.faceShield:
        return 'Face Shield';
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
      case AlertType.noHelmet:
        return 'No Helmet';
      case AlertType.noVest:
        return 'No Vest';
      case AlertType.noGloves:
        return 'No Gloves';
      case AlertType.noGoggles:
        return 'No Goggles';
      case AlertType.noFaceMask:
        return 'No Mask';
      case AlertType.noSafetyShoes:
        return 'No Shoes';
      case AlertType.noHarness:
        return 'No Harness';
      case AlertType.noEarProtection:
        return 'No Ear Prot.';
      case AlertType.helmet:
        return 'Helmet';
      case AlertType.safetyVest:
        return 'Vest';
      case AlertType.gloves:
        return 'Gloves';
      case AlertType.goggles:
        return 'Goggles';
      case AlertType.faceMask:
        return 'Mask';
      case AlertType.safetyShoes:
        return 'Shoes';
      case AlertType.harness:
        return 'Harness';
      case AlertType.earProtection:
        return 'Ear Prot.';
      case AlertType.protectiveSuit:
        return 'Suit';
      case AlertType.apron:
        return 'Apron';
      case AlertType.faceShield:
        return 'Shield';
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
    if (_violationTypes.contains(type)) {
      return Colors.redAccent;
    }
    if (_complianceTypes.contains(type)) {
      return Colors.green;
    }
    switch (type) {
      case AlertType.cameraOffline:
        return Colors.deepOrange;
      case AlertType.cameraOnline:
        return Colors.green;
      case AlertType.storageWarning:
        return Colors.amber;
      case AlertType.storageCritical:
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  bool get isDetection =>
      _violationTypes.contains(type) || _complianceTypes.contains(type);

  bool get isViolation => _violationTypes.contains(type);

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
      default:
        return 'System';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case AlertType.noHelmet:
      case AlertType.helmet:
        return Icons.engineering_rounded;
      case AlertType.noVest:
      case AlertType.safetyVest:
        return Icons.checkroom_rounded;
      case AlertType.noGloves:
      case AlertType.gloves:
        return Icons.back_hand_rounded;
      case AlertType.noGoggles:
      case AlertType.goggles:
        return Icons.visibility_rounded;
      case AlertType.noFaceMask:
      case AlertType.faceMask:
        return Icons.masks_rounded;
      case AlertType.noSafetyShoes:
      case AlertType.safetyShoes:
        return Icons.hiking_rounded;
      case AlertType.noHarness:
      case AlertType.harness:
        return Icons.link_rounded;
      case AlertType.noEarProtection:
      case AlertType.earProtection:
        return Icons.hearing_rounded;
      case AlertType.protectiveSuit:
        return Icons.health_and_safety_rounded;
      case AlertType.apron:
        return Icons.dry_cleaning_rounded;
      case AlertType.faceShield:
        return Icons.shield_rounded;
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
