import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/first_run/first_run_screen.dart';
import '../models/place.dart';
import '../theme/app_theme.dart';
import 'app_state.dart';
import 'storage.dart';

class UnitanaApp extends StatefulWidget {
  const UnitanaApp({super.key});

  @override
  State<UnitanaApp> createState() => _UnitanaAppState();
}

class _UnitanaAppState extends State<UnitanaApp> {
  late final UnitanaAppState _state = UnitanaAppState(UnitanaStorage());
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _state.load();
    if (!mounted) return;
    setState(() {
      _ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: UnitanaTheme.dark(),
      darkTheme: UnitanaTheme.dark(),
      themeMode: ThemeMode.dark,
      home: _ready
          ? _HomeRouter(state: _state)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }
}

class _HomeRouter extends StatelessWidget {
  final UnitanaAppState state;

  const _HomeRouter({required this.state});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: state,
      builder: (context, _) {
        final isSetupComplete = _isSetupComplete(state);
        return isSetupComplete
            ? DashboardScreen(state: state)
            : FirstRunScreen(state: state);
      },
    );
  }

  static bool _isSetupComplete(UnitanaAppState state) {
    final places = state.places;
    final hasLiving = places.any((p) => p.type == PlaceType.living);
    final hasVisiting = places.any((p) => p.type == PlaceType.visiting);
    return hasLiving && hasVisiting;
  }
}
