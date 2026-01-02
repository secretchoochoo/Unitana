/// Small domain exceptions used to control UI flow without API churn.
///
/// These are intentionally lightweight and string-based so they can be thrown
/// from callbacks that cross modal boundaries.
class DuplicateDashboardWidgetException implements Exception {
  final String toolId;
  final String title;

  const DuplicateDashboardWidgetException({
    required this.toolId,
    required this.title,
  });

  @override
  String toString() => 'DuplicateDashboardWidgetException(toolId: $toolId)';
}
