import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../app/app_state.dart';
import '../../data/city_repository.dart';
import '../../models/place.dart';
import '../../common/feedback/unitana_toast.dart';
import '../first_run/first_run_screen.dart';
import 'models/dashboard_live_data.dart';
import 'models/dashboard_layout_controller.dart';
import 'models/dashboard_session_controller.dart';
import 'models/dashboard_exceptions.dart';
import 'models/tool_definitions.dart';
import 'widgets/dashboard_board.dart';
import 'widgets/tool_modal_bottom_sheet.dart';

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

  Future<void> _resetAndRestart() async {
    await state.resetAll();
    CityRepository.instance.resetCache();
    await _layout.clear();

    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => FirstRunScreen(state: state)),
      (route) => false,
    );
  }

  Future<void> _resetDashboardDefaults() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reset Dashboard Defaults',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This removes any widgets you\'ve added and restores the default dashboard layout.',
                  style: Theme.of(sheetContext).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(sheetContext).pop(false),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(true),
                        child: const Text('Reset'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );

    if (confirmed != true) return;

    await _layout.resetDashboardDefaults();
    if (!mounted) return;

    setState(() {
      _isEditingWidgets = false;
      _focusTileId = null;
    });

    UnitanaToast.showSuccess(
      context,
      'Dashboard reset to defaults.',
      key: const ValueKey('toast_dashboard_reset_defaults'),
    );
  }

  bool _preferMetricForReality() {
    // Align tool defaults with the currently selected "reality" in Places Hero.
    Place? home;
    Place? destination;

    for (final p in state.places) {
      if (home == null && p.type == PlaceType.living) home = p;
      if (destination == null && p.type != PlaceType.living) destination = p;
    }

    final primary = _session.reality == DashboardReality.home
        ? home
        : destination;
    final unitSystem = (primary?.unitSystem ?? 'metric').toLowerCase();
    return unitSystem == 'metric';
  }

  Future<void> _openToolPickerAndRun(BuildContext context) async {
    final picked = await showModalBottomSheet<ToolDefinition>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (ctx) => ToolPickerSheet(session: _session),
    );

    if (picked == null) return;
    if (!context.mounted) return;

    await ToolModalBottomSheet.show(
      context,
      tool: picked,
      session: _session,
      preferMetric: _preferMetricForReality(),
      canAddWidget: true,
      onAddWidget: () async {
        if (_dashboardHasToolId(picked.id)) {
          throw DuplicateDashboardWidgetException(
            toolId: picked.id,
            title: picked.title,
          );
        }
        await _layout.addTool(picked);
      },
    );
  }

  bool _dashboardHasToolId(String toolId) {
    // Includes the default, always-present tiles and user-added tiles.
    if (ToolDefinitions.defaultTiles.any((t) => t.id == toolId)) return true;
    return _layout.items.any((i) => i.toolId == toolId);
  }

  void _comingSoon(BuildContext context, String label) {
    UnitanaToast.showInfo(context, '$label: coming soon');
  }

  void _openToolPickerFromMenu() {
    if (!mounted) return;
    _openToolPickerAndRun(context);
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
    UnitanaToast.showSuccess(context, 'Dashboard updated');
  }

  @override
  Widget build(BuildContext context) {
    final profileName = state.profileName.trim().isEmpty
        ? 'My Places'
        : state.profileName.trim();

    return AnimatedBuilder(
      animation: Listenable.merge([_session, _liveData, _layout]),
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            // AppBar has a fixed height (typically 56). Avoid stacking text
            // under the icon here because it causes overflows on small phones.
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Tooltip(
                message: 'Tools',
                child: _ToolsButton(
                  key: const Key('dashboard_tools_button'),
                  onTap: _openToolPickerFromMenu,
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
                                key: const ValueKey(
                                  'dashboard_menu_reset_defaults',
                                ),
                                leading: const Icon(Icons.restore),
                                title: const Text('Reset Dashboard Defaults'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  Future.microtask(_resetDashboardDefaults);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.restart_alt),
                                title: const Text('Reset and restart'),
                                onTap: () {
                                  Navigator.of(sheetContext).pop();
                                  _resetAndRestart();
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

class _ToolsButton extends StatelessWidget {
  final VoidCallback onTap;

  const _ToolsButton({super.key, required this.onTap});

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
        child: Icon(
          Icons.grid_view_rounded,
          color: cs.onSurface.withAlpha(210),
        ),
      ),
    );
  }
}
