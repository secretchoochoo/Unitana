import 'package:flutter/material.dart';
import '../../app/app_state.dart';
import '../../app/app.dart';

class DashboardScreen extends StatelessWidget {
  final UnitanaAppState state;
  const DashboardScreen({super.key, required this.state});

  Future<void> _resetAndReroute(BuildContext context) async {
    await state.resetAll();

    // Replace the navigation stack with a fresh UnitanaApp instance.
    // UnitanaApp will re-bootstrap state and route to FirstRunScreen because
    // defaultPlaceId is now cleared.
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const UnitanaApp()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Unitana'),
        actions: [
          TextButton(
            onPressed: () => _resetAndReroute(context),
            child: const Text('Reset'),
          ),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Dashboard reads from stored Places next.'),
      ),
    );
  }
}
