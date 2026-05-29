import 'package:flutter_test/flutter_test.dart';
import 'package:security_app/models/alert.dart';
import 'package:security_app/services/alert_review_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('reviewed alert ids include legacy last alert id', () async {
    SharedPreferences.setMockInitialValues({
      kBgLastAlertId: 'legacy-alert',
      'reviewed_alert_ids': ['reviewed-alert'],
    });

    final ids = await loadReviewedAlertIds();

    expect(ids, containsAll(['legacy-alert', 'reviewed-alert']));
  });

  test('saveReviewedAlertId persists reviewed ids and background last id',
      () async {
    SharedPreferences.setMockInitialValues({});

    final ids = await saveReviewedAlertId({'older-alert'}, 'new-alert');
    final prefs = await SharedPreferences.getInstance();

    expect(ids, containsAll(['new-alert', 'older-alert']));
    expect(prefs.getString(kBgLastAlertId), 'new-alert');
    expect(
      prefs.getStringList('reviewed_alert_ids'),
      containsAll(['new-alert', 'older-alert']),
    );
  });

  test('alertReviewKey falls back to stable alert fields when id is missing',
      () {
    final alert = Alert(
      id: '',
      type: AlertType.cameraOffline,
      cameraId: 'cam-1',
      cameraName: 'Front Door',
      timestamp: DateTime.utc(2026, 5, 28, 10, 30),
    );

    expect(
      alertReviewKey(alert),
      'cameraOffline|cam-1|Front Door|2026-05-28T10:30:00.000Z',
    );
  });
}
