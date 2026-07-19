import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'rookery/flight_deck.dart';
import 'rookery/infra/debug_flock.dart';
import 'store.dart';

/// Shared game-progress store used by the white-part screens.
final ReaderStore store = ReaderStore();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase and AppCheck are initialised in independent try/catch blocks:
  // an AppCheck debug-token error must NEVER disable the gray flow
  // (gray_flow_lessons.md #5).
  try {
    await Firebase.initializeApp();
  } catch (e) {
    flockLog(() => '[FEG.main] firebase err=$e');
  }
  try {
    await FirebaseAppCheck.instance.activate(
      providerApple: kReleaseMode
          ? const AppleDeviceCheckProvider()
          : const AppleDebugProvider(),
    );
  } catch (e) {
    flockLog(() => '[FEG.main] appcheck err=$e');
  }

  runApp(const FlightDeckApp());
}
