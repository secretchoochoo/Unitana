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

  test(
    'DST transition conversion remains deterministic for America/New_York',
    () {
      final beforeJumpUtc = TimezoneUtils.localToUtc(
        'America/New_York',
        DateTime(2026, 3, 8, 1, 30),
      );
      final afterJumpUtc = TimezoneUtils.localToUtc(
        'America/New_York',
        DateTime(2026, 3, 8, 3, 30),
      );

      final beforeJumpLocal = TimezoneUtils.nowInZone(
        'America/New_York',
        nowUtc: beforeJumpUtc,
      );
      final afterJumpLocal = TimezoneUtils.nowInZone(
        'America/New_York',
        nowUtc: afterJumpUtc,
      );

      expect(beforeJumpLocal.local.hour, 1);
      expect(beforeJumpLocal.local.minute, 30);
      expect(afterJumpLocal.local.hour, 3);
      expect(afterJumpLocal.local.minute, 30);
      expect(afterJumpUtc.difference(beforeJumpUtc).inHours, 1);
    },
  );

  test('date-line opposite direction offsets stay deterministic', () {
    final utc = DateTime.utc(2026, 1, 1, 12, 0);
    final kiritimati = TimezoneUtils.nowInZone(
      'Pacific/Kiritimati',
      nowUtc: utc,
    );
    final honolulu = TimezoneUtils.nowInZone('Pacific/Honolulu', nowUtc: utc);

    expect(kiritimati.local.day, 2);
    expect(honolulu.local.day, 1);
    expect(kiritimati.offsetMinutes - honolulu.offsetMinutes, 24 * 60);
    expect(TimezoneUtils.deltaHours(kiritimati, honolulu), 24);
    expect(TimezoneUtils.deltaHours(honolulu, kiritimati), -24);
  });

  test('strict mode rejects unknown timezone IDs', () {
    expect(
      () => TimezoneUtils.nowInZone(
        'Mars/Olympus_Mons',
        fallbackToUtcOnUnknown: false,
      ),
      throwsArgumentError,
    );
    expect(
      () => TimezoneUtils.localToUtc(
        'Mars/Olympus_Mons',
        DateTime(2026, 1, 1, 0, 0),
        fallbackToUtcOnUnknown: false,
      ),
      throwsArgumentError,
    );
  });
}
