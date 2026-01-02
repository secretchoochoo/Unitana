import 'package:flutter/material.dart';

/// Dracula theme reference palette.
///
/// Keep these as canonical constants so we don't scatter hex values across UI.
/// The app theme uses a Dracula-inspired dark palette (see draculatheme.com).
class DraculaPalette {
  const DraculaPalette._();

  // Core surfaces.
  static const Color background = Color(0xFF282A36);
  static const Color currentLine = Color(0xFF44475A);
  static const Color foreground = Color(0xFFF8F8F2);
  static const Color comment = Color(0xFF6272A4);

  // Accents.
  static const Color cyan = Color(0xFF8BE9FD);
  static const Color green = Color(0xFF50FA7B);
  static const Color orange = Color(0xFFFFB86C);
  static const Color pink = Color(0xFFFF79C6);
  static const Color purple = Color(0xFFBD93F9);
  static const Color red = Color(0xFFFF5555);
  static const Color yellow = Color(0xFFF1FA8C);
}
