import 'package:flutter/material.dart';

import '../../app/app_state.dart';
import '../../data/city_repository.dart';
import '../first_run/first_run_screen.dart';
import 'widgets/dashboard_board.dart';

enum _DashboardMenuAction { switchProfile, addProfile, settings, reset }

class DashboardScreen extends StatelessWidget {
  final UnitanaAppState state;

  const DashboardScreen({super.key, required this.state});

  Future<void> _resetAndRestart(BuildContext context) async {
    await state.resetAll();
    CityRepository.instance.resetCache();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => FirstRunScreen(state: state)),
      (route) => false,
    );
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label: coming soon')));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final profileName = state.profileName.trim().isEmpty
        ? 'My Places'
        : state.profileName.trim();
    final initial = profileName.characters.first.toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: Text(profileName),
        leading: Padding(
          padding: const EdgeInsets.all(8),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cs.surface,
              shape: BoxShape.circle,
              border: Border.all(color: cs.outline),
            ),
            child: Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        actions: [
          PopupMenuButton<_DashboardMenuAction>(
            tooltip: 'Menu',
            onSelected: (action) {
              switch (action) {
                case _DashboardMenuAction.switchProfile:
                  _comingSoon(context, 'Switch profile');
                  break;
                case _DashboardMenuAction.addProfile:
                  _comingSoon(context, 'Add profile (Premium)');
                  break;
                case _DashboardMenuAction.settings:
                  _comingSoon(context, 'Settings');
                  break;
                case _DashboardMenuAction.reset:
                  _resetAndRestart(context);
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _DashboardMenuAction.switchProfile,
                child: Text('Switch profile'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.addProfile,
                child: Text('Add profile (Premium)'),
              ),
              PopupMenuItem(
                value: _DashboardMenuAction.settings,
                child: Text('Settings'),
              ),
              PopupMenuDivider(),
              PopupMenuItem(
                value: _DashboardMenuAction.reset,
                child: Text('Reset and restart'),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final padding = width >= 600
              ? const EdgeInsets.all(24)
              : const EdgeInsets.all(16);

          return SingleChildScrollView(
            padding: padding,
            child: DashboardBoard(
              state: state,
              availableWidth: width - padding.horizontal,
            ),
          );
        },
      ),
    );
  }
}
