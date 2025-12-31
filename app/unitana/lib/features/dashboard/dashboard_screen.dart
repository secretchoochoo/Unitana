import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_state.dart';
import '../../data/city_repository.dart';
import '../first_run/first_run_screen.dart';
import 'models/dashboard_live_data.dart';
import 'models/dashboard_layout_controller.dart';
import 'models/dashboard_session_controller.dart';
import 'models/tool_definitions.dart';
import 'widgets/dashboard_board.dart';

class DashboardScreen extends StatefulWidget {
  final UnitanaAppState state;

  const DashboardScreen({super.key, required this.state});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final DashboardSessionController _session;
  late final DashboardLiveDataController _liveData;
  late final DashboardLayoutController _layout;

  bool _isEditingWidgets = false;
  String? _focusTileId;

  UnitanaAppState get state => widget.state;

  @override
  void initState() {
    super.initState();
    _session = DashboardSessionController();
    _liveData = DashboardLiveDataController();
    _layout = DashboardLayoutController();
    _layout.load();
  }

  @override
  void dispose() {
    _session.dispose();
    _liveData.dispose();
    _layout.dispose();
    super.dispose();
  }

  Future<void> _resetAndRestart(BuildContext context) async {
    await state.resetAll();
    CityRepository.instance.resetCache();
    await _layout.clear();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => FirstRunScreen(state: state)),
      (route) => false,
    );
  }

  Future<void> _onRefreshAll(BuildContext context) async {
    if (_liveData.isRefreshing) return;
    final places = state.places;
    if (places.isEmpty) return;

    await _liveData.refreshAll(places: places);

    // Guard the specific BuildContext since this method accepts one.
    if (!context.mounted) return;
    final err = _liveData.lastError;
    if (err != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Refresh failed.')));
    }
  }

  Future<void> _openToolPickerAndAdd(BuildContext context) async {
    final picked = await showModalBottomSheet<ToolDefinition>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => const ToolPickerSheet(),
    );
    if (picked == null) return;
    if (!context.mounted) return;

    await _layout.addTool(picked);

    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added ${picked.title}')));
  }

  void _comingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label: coming soon')));
  }

  void _openToolPickerFromMenu() {
    if (!mounted) return;
    _openToolPickerAndAdd(context);
  }

  void _enterEditWidgets({String? focusTileId}) {
    if (_isEditingWidgets) return;
    _layout.beginEdit();
    setState(() {
      _isEditingWidgets = true;
      _focusTileId = focusTileId;
    });
  }

  Future<void> _exitEditWidgetsCancel() async {
    if (!_isEditingWidgets) return;
    _layout.cancelEdit();
    if (!mounted) return;
    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
  }

  Future<void> _exitEditWidgetsDone() async {
    if (!_isEditingWidgets) return;
    await _layout.commitEdit();
    if (!mounted) return;
    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Dashboard updated.')));
  }

  @override
  Widget build(BuildContext context) {
    final profileName = state.profileName.trim().isEmpty
        ? 'My Places'
        : state.profileName.trim();

    return AnimatedBuilder(
      animation: Listenable.merge([_session, _liveData, _layout]),
      builder: (context, _) {
        final refreshedAt = _liveData.lastRefreshedAt;
        final refreshedLabel = refreshedAt == null
            ? null
            : 'Updated ${TimeOfDay.fromDateTime(refreshedAt).format(context)}';

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            // AppBar has a fixed height (typically 56). Avoid stacking text
            // under the icon here because it causes overflows on small phones.
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Tooltip(
                message: refreshedLabel == null
                    ? 'Refresh'
                    : 'Refresh. $refreshedLabel',
                child: _RefreshButton(
                  isRefreshing: _liveData.isRefreshing,
                  onTap: () => _onRefreshAll(context),
                ),
              ),
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.center,
              child: Text(
                profileName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                textAlign: TextAlign.center,
                style: GoogleFonts.shadowsIntoLight(
                  textStyle: Theme.of(context).textTheme.titleLarge,
                ).copyWith(fontSize: 30, height: 1.0),
              ),
            ),
            actions: [
              if (_isEditingWidgets) ...[
                IconButton(
                  key: const Key('dashboard_edit_cancel'),
                  icon: const Icon(Icons.close),
                  tooltip: 'Cancel',
                  onPressed: _exitEditWidgetsCancel,
                ),
                IconButton(
                  key: const Key('dashboard_edit_done'),
                  icon: const Icon(Icons.check),
                  tooltip: 'Done',
                  onPressed: _exitEditWidgetsDone,
                ),
              ] else
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      showDragHandle: true,
                      builder: (sheetContext) {
                        return SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.grid_view_rounded),
                                title: const Text('Tools'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  Future.microtask(_openToolPickerFromMenu);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.edit),
                                title: const Text('Edit widgets'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  Future.microtask(() {
                                    if (!mounted) return;
                                    _enterEditWidgets();
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.switch_account),
                                title: const Text('Switch profile'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  _comingSoon(context, 'Switch profile');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.person_add_alt_1),
                                title: const Text('Add profile'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  _comingSoon(context, 'Add profile');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.settings),
                                title: const Text('Settings'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  _comingSoon(context, 'Settings');
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.restart_alt),
                                title: const Text('Reset and restart'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
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
                  session: _session,
                  liveData: _liveData,
                  layout: _layout,
                  availableWidth: width - padding.horizontal,
                  isEditing: _isEditingWidgets,
                  focusActionTileId: _focusTileId,
                  onEnteredEditMode: (tileId) {
                    if (_isEditingWidgets) return;
                    _enterEditWidgets(focusTileId: tileId);
                  },
                  onConsumedFocusTileId: () {
                    if (_focusTileId == null) return;
                    setState(() {
                      _focusTileId = null;
                    });
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RefreshButton extends StatelessWidget {
  final bool isRefreshing;
  final VoidCallback onTap;

  const _RefreshButton({required this.isRefreshing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withAlpha(89),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: cs.outlineVariant.withAlpha(179), width: 1),
        ),
        alignment: Alignment.center,
        child: AnimatedRotation(
          turns: isRefreshing ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 500),
          child: Icon(
            Icons.refresh_rounded,
            color: cs.onSurface.withAlpha(210),
          ),
        ),
      ),
    );
  }
}
