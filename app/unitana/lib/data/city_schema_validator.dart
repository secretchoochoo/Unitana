import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class CitySchemaValidator {
  static const requiredFields = <String>[
    'id',
    'cityName',
    'countryCode',
    'timeZoneId',
    'currencyCode',
    'defaultUnitSystem',
    'defaultUse24h',
    'lat',
    'lon',
  ];

  static const supportedUnitSystems = <String>{'metric', 'imperial'};
  static final RegExp _alpha2Pattern = RegExp(r'^[A-Z]{2}$');
  static final RegExp _alpha3Pattern = RegExp(r'^[A-Z]{3}$');
  static bool _tzReady = false;
  static final Map<String, bool> _timeZoneValidityCache = <String, bool>{};

  static void _ensureTzReady() {
    if (_tzReady) return;
    tzdata.initializeTimeZones();
    _tzReady = true;
  }

  static bool _isValidTimeZoneId(String? value) {
    final tzId = (value ?? '').trim();
    if (tzId.isEmpty) return false;
    final cached = _timeZoneValidityCache[tzId];
    if (cached != null) return cached;
    _ensureTzReady();
    try {
      tz.getLocation(tzId);
      _timeZoneValidityCache[tzId] = true;
      return true;
    } catch (_) {
      _timeZoneValidityCache[tzId] = false;
      return false;
    }
  }

  static List<String> validateRecord(Map<String, dynamic> row) {
    final errors = <String>[];

    for (final field in requiredFields) {
      if (!row.containsKey(field)) {
        errors.add('missing $field');
      }
    }

    final id = row['id'];
    final cityName = row['cityName'];
    final countryCode = row['countryCode'];
    final timeZoneId = row['timeZoneId'];
    final currencyCode = row['currencyCode'];
    final unitSystem = row['defaultUnitSystem'];
    final use24h = row['defaultUse24h'];
    final lat = row['lat'];
    final lon = row['lon'];

    if (!_nonEmptyString(id)) errors.add('invalid id');
    if (!_nonEmptyString(cityName)) errors.add('invalid cityName');
    if (!_nonEmptyString(countryCode)) errors.add('invalid countryCode');
    if (!_nonEmptyString(timeZoneId)) {
      errors.add('invalid timeZoneId');
    } else if (!_isValidTimeZoneId(timeZoneId as String?)) {
      errors.add('timeZoneId is not a known IANA timezone');
    }
    if (!_nonEmptyString(currencyCode)) errors.add('invalid currencyCode');

    final cc = countryCode is String ? countryCode.trim().toUpperCase() : '';
    if (!_alpha2Pattern.hasMatch(cc)) {
      errors.add('countryCode must be ISO-3166 alpha-2');
    }

    final cur = currencyCode is String ? currencyCode.trim().toUpperCase() : '';
    if (!_alpha3Pattern.hasMatch(cur)) {
      errors.add('currencyCode must be ISO-4217 alpha-3');
    }

    if (unitSystem is! String || !supportedUnitSystems.contains(unitSystem)) {
      errors.add('invalid defaultUnitSystem');
    }
    if (use24h is! bool) errors.add('invalid defaultUse24h');

    if (lat is! num || lat < -90 || lat > 90) {
      errors.add('invalid latitude');
    }
    if (lon is! num || lon < -180 || lon > 180) {
      errors.add('invalid longitude');
    }

    return errors;
  }

  static bool _nonEmptyString(Object? value) {
    return value is String && value.trim().isNotEmpty;
  }
}
