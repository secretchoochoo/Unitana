import 'package:flutter/material.dart';

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
  late final UnitanaAppState _state;
  late final Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();
    _state = UnitanaAppState(UnitanaStorage());
    _loadFuture = _state.load(); // ✅ correct API (not loadState)
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF2E5C8A),
    );

    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        // Basic startup shell while loading persisted state
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: theme,
            home: const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // ✅ Reactive rebuild on onboarding completion (notifyListeners)
        return AnimatedBuilder(
          animation: _state,
          builder: (context, _) {
            final bool isOnboarded =
                _state.defaultPlaceId != null && _state.places.isNotEmpty;

            return MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: theme,
              home: isOnboarded
                  ? DashboardScreen(state: _state)
                  : FirstRunScreen(state: _state),
            );
          },
        );
      },
    );
  }
}
