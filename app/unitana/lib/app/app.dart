import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../features/first_run/first_run_screen.dart';

class UnitanaApp extends StatelessWidget {
  const UnitanaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Unitana',
      theme: UnitanaTheme.light(),
      darkTheme: UnitanaTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: const FirstRunScreen(),
    );
  }
}

