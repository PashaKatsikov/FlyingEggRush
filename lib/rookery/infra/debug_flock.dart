import 'package:flutter/foundation.dart';

/// Assert-wrapped logger. The closure AND its string literals are stripped
/// from release builds so log tags never leak into the binary.
///
/// Usage:  flockLog(() => '[FEG.dispatch] body=$body');
void flockLog(String Function() build) {
  assert(() {
    debugPrint(build());
    return true;
  }());
}
