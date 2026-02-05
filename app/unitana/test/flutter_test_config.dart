import 'dart:async';

import 'package:google_fonts/google_fonts.dart';

/// Global Flutter test configuration.
///
/// Unitana uses the `google_fonts` package (Roboto Slab, Roboto Mono, etc.).
/// In widget tests (including goldens), `HttpClient` requests are blocked and
/// `google_fonts` runtime fetching will fail unless disabled.
///
/// We disable runtime fetching for deterministic tests. Fonts will fall back to
/// the default test font unless they are bundled as local assets.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;
  await testMain();
}
