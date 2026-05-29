import 'package:shared_preferences/shared_preferences.dart';

import '../models/alert.dart';

const kBgLastAlertId = 'bg_last_alert_id';

const _kReviewedAlertIds = 'reviewed_alert_ids';
const _maxReviewedAlertIds = 500;

String alertReviewKey(Alert alert) {
  if (alert.id.trim().isNotEmpty) {
    return alert.id.trim();
  }

  return [
    alert.type.name,
    alert.cameraId.trim(),
    alert.cameraName.trim(),
    alert.timestamp.toUtc().toIso8601String(),
  ].join('|');
}

Future<Set<String>> loadReviewedAlertIds() async {
  final prefs = await SharedPreferences.getInstance();
  final reviewed = prefs.getStringList(_kReviewedAlertIds) ?? const <String>[];
  final legacyLastId = prefs.getString(kBgLastAlertId);

  return {
    ...reviewed.where((id) => id.trim().isNotEmpty),
    if (legacyLastId != null && legacyLastId.trim().isNotEmpty)
      legacyLastId.trim(),
  };
}

Future<Set<String>> saveReviewedAlertId(
  Set<String> currentIds,
  String alertKey,
) async {
  final key = alertKey.trim();
  if (key.isEmpty) return currentIds;

  final ids = <String>{key, ...currentIds.where((id) => id.trim().isNotEmpty)};
  final cappedIds = ids.take(_maxReviewedAlertIds).toList(growable: false);

  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList(_kReviewedAlertIds, cappedIds);
  await prefs.setString(kBgLastAlertId, key);

  return cappedIds.toSet();
}
