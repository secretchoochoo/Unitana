/// Shared formatting for user-facing IANA timezone labels.
class TimeZoneLabelUtils {
  const TimeZoneLabelUtils._();

  static String clean(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return raw;
    final segments = trimmed
        .split('/')
        .map(_cleanSegment)
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    if (segments.isEmpty) return trimmed;
    return segments.join('/');
  }

  static String _cleanSegment(String input) {
    var segment = input.trim().replaceAll('_', ' ');
    segment = segment.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (segment.isEmpty) return '';

    final lettersOnly = segment.replaceAll(RegExp(r'[^A-Za-z]'), '');
    final allUpper =
        lettersOnly.length >= 2 && lettersOnly == lettersOnly.toUpperCase();
    if (allUpper && lettersOnly.length <= 5) {
      return segment;
    }
    return segment;
  }
}
