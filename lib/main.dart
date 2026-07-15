import 'package:flutter/material.dart';

import 'screens/loading_screen.dart';
import 'store.dart';
import 'theme.dart';

/// Single shared progress store for the whole app.
final ReaderStore store = ReaderStore();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ChickenTimesApp());
}

class ChickenTimesApp extends StatelessWidget {
  const ChickenTimesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flying Egg Rush',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.gold,
          brightness: Brightness.light,
        ),
        fontFamily: 'Georgia',
      ),
      home: const LoadingScreen(),
    );
  }
}
