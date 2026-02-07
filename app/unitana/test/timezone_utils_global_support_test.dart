import 'package:flutter_test/flutter_test.dart';
import 'package:unitana/utils/timezone_utils.dart';

void main() {
  test('TimezoneUtils resolves non-curated IANA zones', () {
    final utc = DateTime.utc(2026, 2, 7, 12, 0);
    final india = TimezoneUtils.nowInZone('Asia/Kolkata', nowUtc: utc);
    final denver = TimezoneUtils.nowInZone('America/Denver', nowUtc: utc);

    expect(india.offsetMinutes, 330);
    expect(denver.offsetMinutes, isNot(0));
    expect(TimezoneUtils.deltaHours(india, denver), greaterThanOrEqualTo(11));
  });

  test('localToUtc converts arbitrary zone wall-clock time', () {
    final utc = TimezoneUtils.localToUtc('Asia/Tokyo', DateTime(2026, 6, 1, 9));
    final tokyo = TimezoneUtils.nowInZone('Asia/Tokyo', nowUtc: utc);
    expect(tokyo.local.hour, 9);
    expect(tokyo.local.minute, 0);
  });
}
