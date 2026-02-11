import 'cities.dart';

/// Shared city/country display cleanup used across pickers.
class CityLabelUtils {
  static String countryFlag(String countryCode) {
    final cc = countryCode.trim().toUpperCase();
    if (cc.length != 2) return '';
    final first = cc.codeUnitAt(0);
    final second = cc.codeUnitAt(1);
    final a = 'A'.codeUnitAt(0);
    final z = 'Z'.codeUnitAt(0);
    if (first < a || first > z || second < a || second > z) return '';
    const base = 0x1F1E6;
    return String.fromCharCode(base + (first - a)) +
        String.fromCharCode(base + (second - a));
  }

  static String cleanCityName(String raw) {
    var s = raw.trim().replaceAll('_', ' ');
    if (s.isEmpty) return raw;

    // Trim noisy leading punctuation from data-source aliases.
    s = s.replaceFirst(
      RegExp("^[\\s'\\\"`.,;:!?~^*_+=|/\\\\()\\[\\]{}<>-]+"),
      '',
    );
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (s.isEmpty) return raw.trim();

    // If the source is all-caps, normalize to title case for readability.
    final lettersOnly = s.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (lettersOnly.length >= 3 && lettersOnly == lettersOnly.toUpperCase()) {
      s = _titleCaseWords(s);
    }
    return s;
  }

  static String cleanCountryLabel(City city) {
    final name = (city.countryName ?? '').trim();
    if (name.isNotEmpty) return name;
    return city.countryCode.toUpperCase();
  }

  static String _titleCaseWords(String input) {
    final parts = input.split(' ');
    return parts
        .map((word) {
          if (word.isEmpty) return word;
          final lower = word.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}
