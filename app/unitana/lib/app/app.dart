import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_state.dart';
import 'storage.dart';
import '../features/first_run/first_run_screen.dart';
import '../features/dashboard/dashboard_screen.dart';

class UnitanaApp extends StatefulWidget {
  const UnitanaApp({super.key});

  @override
  State<UnitanaApp> createState() => _UnitanaAppState();
}

class _UnitanaAppState extends State<UnitanaApp> {
  final _state = UnitanaAppState(storage: UnitanaStorage());
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _state.load();
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: 'Unitana',
        theme: UnitanaTheme.light(),
        darkTheme: UnitanaTheme.dark(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return MaterialApp(
      title: 'Unitana',
      theme: UnitanaTheme.light(),
      darkTheme: UnitanaTheme.dark(),
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: _state.hasDefaultPlace
          ? DashboardScreen(state: _state)
          : FirstRunScreen(state: _state),
    );
  }
}

