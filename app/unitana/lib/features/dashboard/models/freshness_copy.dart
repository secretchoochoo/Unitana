class FreshnessCopy {
  const FreshnessCopy._();

  static String relativeAgeShort({
    required DateTime now,
    required DateTime then,
  }) {
    final age = now.difference(then);
    if (age.inSeconds < 60) return 'just now';
    if (age.inMinutes < 60) return '${age.inMinutes}m ago';
    if (age.inHours < 24) return '${age.inHours}h ago';
    return '${age.inDays}d ago';
  }
}
