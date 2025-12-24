import 'package:flutter/material.dart';
import '../../app/app_state.dart';

class DashboardScreen extends StatelessWidget {
  final UnitanaAppState state;
  const DashboardScreen({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Unitana')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Dashboard reads from stored Places next.'),
      ),
    );
  }
}

