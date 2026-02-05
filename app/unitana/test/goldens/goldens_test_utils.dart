import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Goldens are opt-in by default.
///
/// Enable by setting `UNITANA_GOLDENS=1` or by running
/// `flutter test --update-goldens`.
bool goldensEnabled() {
  return Platform.environment['UNITANA_GOLDENS'] == '1' ||
      autoUpdateGoldenFiles;
}
