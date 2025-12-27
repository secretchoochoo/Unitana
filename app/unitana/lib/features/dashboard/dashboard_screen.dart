import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_state.dart';
import '../../data/city_repository.dart';
import '../../models/place.dart';
import '../first_run/first_run_screen.dart';
import 'widgets/dashboard_board.dart';

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
    final profileName = state.profileName.trim().isEmpty
        ? 'My Places'
        : state.profileName.trim();

    Place? destination;
    try {
      destination = state.places.firstWhere(
        (p) => p.type == PlaceType.visiting,
      );
    } catch (_) {
      destination = null;
    }
    final profileEmoji = _flagEmojiFromIso2(destination?.countryCode);

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: _ProfileBadge(emoji: profileEmoji),
        ),
        title: Text(
          profileName,
          textAlign: TextAlign.center,
          style: GoogleFonts.shadowsIntoLight(
            textStyle: Theme.of(context).textTheme.titleLarge,
          ).copyWith(fontSize: 30, height: 1.0),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: () {
              showModalBottomSheet<void>(
                context: context,
                showDragHandle: true,
                builder: (context) {
                  return SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.switch_account),
                          title: const Text('Switch profile'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _comingSoon(context, 'Switch profile');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.person_add_alt_1),
                          title: const Text('Add profile'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _comingSoon(context, 'Add profile');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.settings),
                          title: const Text('Settings'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _comingSoon(context, 'Settings');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.restart_alt),
                          title: const Text('Reset and restart'),
                          onTap: () {
                            Navigator.of(context).pop();
                            _resetAndRestart(context);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  );
                },
              );
            },
          ),
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

class _ProfileBadge extends StatelessWidget {
  const _ProfileBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        // Avoid deprecated `withOpacity` (precision loss in recent Flutter).
        // 0.35 * 255 ≈ 89
        color: cs.surfaceContainerHighest.withAlpha(89),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          // 0.70 * 255 ≈ 179
          color: cs.outlineVariant.withAlpha(179),
          width: 1,
        ),
      ),
      alignment: Alignment.center,
      child: Text(emoji, style: const TextStyle(fontSize: 18)),
    );
  }
}

String _flagEmojiFromIso2(String? iso2) {
  final code = (iso2 ?? '').trim().toUpperCase();
  if (code.length != 2) return '🌐';
  final a = code.codeUnitAt(0);
  final b = code.codeUnitAt(1);
  if (a < 65 || a > 90 || b < 65 || b > 90) return '🌐';
  return String.fromCharCodes(<int>[0x1F1E6 + (a - 65), 0x1F1E6 + (b - 65)]);
}
