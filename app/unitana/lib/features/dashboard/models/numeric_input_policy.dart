import 'package:flutter/services.dart';

/// A simple, shared policy for numeric TextFields.
///
/// Goals:
/// - Avoid visual overflow in tiles/modals by limiting inputs.
/// - Keep behavior predictable across tools.
/// - Allow targeted exceptions (e.g. temperature negatives).
class NumericInputPolicy {
  /// Maximum digits allowed *before* the decimal separator.
  final int maxWholeDigits;

  /// Maximum digits allowed *after* the decimal separator.
  final int maxFractionDigits;

  /// Whether to allow a leading negative sign.
  final bool allowNegative;

  /// Whether to allow a decimal separator.
  final bool allowDecimal;

  const NumericInputPolicy({
    required this.maxWholeDigits,
    required this.maxFractionDigits,
    required this.allowNegative,
    required this.allowDecimal,
  });

  int get maxTotalDigits =>
      maxWholeDigits + (allowDecimal ? maxFractionDigits : 0);
}

class ToolNumericPolicies {
  static const NumericInputPolicy _default = NumericInputPolicy(
    maxWholeDigits: 8,
    maxFractionDigits: 2,
    allowNegative: false,
    allowDecimal: true,
  );

  static const NumericInputPolicy _temperature = NumericInputPolicy(
    maxWholeDigits: 3,
    maxFractionDigits: 1,
    allowNegative: true,
    allowDecimal: true,
  );

  static const NumericInputPolicy _heightCm = NumericInputPolicy(
    maxWholeDigits: 3,
    maxFractionDigits: 1,
    allowNegative: false,
    allowDecimal: true,
  );

  static const NumericInputPolicy _area = NumericInputPolicy(
    maxWholeDigits: 7,
    maxFractionDigits: 2,
    allowNegative: false,
    allowDecimal: true,
  );

  static NumericInputPolicy forToolId(String toolId) {
    return switch (toolId) {
      'temperature' => _temperature,
      // Height (cm side) is typically 2-3 digits; keep it tight.
      'height' => _heightCm,
      // Area can blow up quickly; keep whole digits a bit tighter.
      'area' => _area,
      _ => _default,
    };
  }
}

/// Restricts a TextField to a numeric format, with digit limits.
///
/// Notes:
/// - Decimal separator is '.' (intentionally simple for now).
/// - If an edit violates the policy, the previous value is retained.
class NumericTextInputFormatter extends TextInputFormatter {
  final NumericInputPolicy policy;

  const NumericTextInputFormatter({required this.policy});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final t = newValue.text;
    if (t.isEmpty) return newValue;

    // Allow a standalone negative sign while typing.
    if (policy.allowNegative && t == '-') {
      return newValue;
    }

    // Reject any characters other than digits, optional leading '-', and optional '.'.
    final allowed = RegExp(
      policy.allowDecimal ? r'^-?[0-9]*\.?[0-9]*$' : r'^-?[0-9]*$',
    );
    if (!allowed.hasMatch(t)) {
      return oldValue;
    }

    if (!policy.allowNegative && t.startsWith('-')) {
      return oldValue;
    }

    if (!policy.allowDecimal && t.contains('.')) {
      return oldValue;
    }

    final normalized = t.startsWith('-') ? t.substring(1) : t;
    final parts = normalized.split('.');
    if (parts.length > 2) return oldValue;

    final whole = parts[0];
    final frac = parts.length == 2 ? parts[1] : '';

    if (whole.length > policy.maxWholeDigits) return oldValue;
    if (frac.length > policy.maxFractionDigits) return oldValue;

    return newValue;
  }
}
