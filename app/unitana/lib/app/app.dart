import 'package:flutter/material.dart';

import '../features/dashboard/dashboard_screen.dart';
import '../features/first_run/first_run_screen.dart';
import '../theme/app_theme.dart';
import 'app_state.dart';
import 'storage.dart';

class UnitanaApp extends StatefulWidget {
  const UnitanaApp({super.key});

  @override
  State<UnitanaApp> createState() => _UnitanaAppState();
}

class _UnitanaAppState extends State<UnitanaApp> {
  late final UnitanaAppState _state;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _state = UnitanaAppState(UnitanaStorage());
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await _state.load();
    if (!mounted) return;
    setState(() => _loading = false);
  }

  bool _isOnboarded(UnitanaAppState state) {
    // "Onboarded" means we have a default place id and it resolves to a place.
    // This protects us from a stale defaultPlaceId.
    return state.defaultPlaceId != null && state.defaultPlace != null;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        title: 'Unitana',
        theme: UnitanaTheme.light(),
        darkTheme: UnitanaTheme.dark(),
        themeMode: ThemeMode.system,
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    return AnimatedBuilder(
      animation: _state,
      builder: (context, _) {
        final onboarded = _isOnboarded(_state);
        return MaterialApp(
          title: 'Unitana',
          theme: UnitanaTheme.light(),
          darkTheme: UnitanaTheme.dark(),
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          home: onboarded
              ? DashboardScreen(state: _state)
              : FirstRunScreen(state: _state),
        );
      },
    );
  }
}
