import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_state.dart';
import '../../../common/feedback/unitana_toast.dart';
import '../../../models/place.dart';
import '../models/dashboard_copy.dart';
import 'destructive_confirmation_sheet.dart';

class ProfilesBoardScreen extends StatefulWidget {
  final UnitanaAppState state;
  final Future<void> Function(String profileId) onSwitchProfile;
  final Future<void> Function(String profileId) onEditProfile;
  final Future<void> Function() onAddProfile;
  final Future<void> Function(String profileId) onDeleteProfile;

  const ProfilesBoardScreen({
    super.key,
    required this.state,
    required this.onSwitchProfile,
    required this.onEditProfile,
    required this.onAddProfile,
    required this.onDeleteProfile,
  });

  @override
  State<ProfilesBoardScreen> createState() => _ProfilesBoardScreenState();
}

class _ProfilesBoardScreenState extends State<ProfilesBoardScreen>
    with SingleTickerProviderStateMixin {
  static const int _kMinAddTileCount = 4;
  static const int _kMinTotalGridCells = 10;
  static const double _kEditAppBarActionFontSize = 14;
  static const double _kDragFeedbackWidth = 160;
  static const double _kDragFeedbackHeight = 186;

  bool _editMode = false;
  List<String> _orderedIds = const <String>[];
  List<String?> _editSlots = const <String?>[];
  String? _draggingId;
  late final AnimationController _wiggle;

  @override
  void initState() {
    super.initState();
    _wiggle = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _syncOrderFromState();
  }

  @override
  void didUpdateWidget(covariant ProfilesBoardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncOrderFromState();
  }

  void _syncOrderFromState() {
    final ids = widget.state.profiles.map((p) => p.id).toList(growable: false);
    if (_orderedIds.isEmpty || !_sameItems(_orderedIds, ids)) {
      _orderedIds = ids;
    }
  }

  void _ensureEditSlots(List<String> orderedIds, int addTileCount) {
    final expectedLength = orderedIds.length + addTileCount;
    final expectedSet = orderedIds.toSet();
    final currentIds = _editSlots.whereType<String>().toSet();
    final needsReset =
        _editSlots.length != expectedLength ||
        currentIds.length != expectedSet.length ||
        !currentIds.containsAll(expectedSet);
    if (!needsReset) return;

    _editSlots = <String?>[
      ...orderedIds,
      ...List<String?>.filled(addTileCount, null),
    ];
  }

  void _commitEditSlots() {
    final nextOrdered = _editSlots.whereType<String>().toList(growable: false);
    if (_sameItems(nextOrdered, _orderedIds) &&
        nextOrdered.length == _orderedIds.length) {
      _orderedIds = nextOrdered;
      return;
    }
    _orderedIds = nextOrdered;
    unawaited(widget.state.reorderProfiles(nextOrdered));
  }

  void _swapDraggedIntoSlot({
    required String draggedId,
    required int targetIndex,
  }) {
    final from = _editSlots.indexOf(draggedId);
    if (from < 0 || targetIndex < 0 || targetIndex >= _editSlots.length) return;
    if (from == targetIndex) return;
    final next = List<String?>.from(_editSlots);
    final tmp = next[targetIndex];
    next[targetIndex] = draggedId;
    next[from] = tmp;
    setState(() {
      _editSlots = next;
    });
  }

  void _setEditMode(
    bool enabled, {
    List<String>? orderedIds,
    int? addTileCount,
  }) {
    if (_editMode == enabled) return;
    setState(() {
      _editMode = enabled;
      if (enabled) {
        final ids = orderedIds ?? _orderedIds;
        final add = addTileCount ?? _addTileCountFor(ids.length);
        _ensureEditSlots(ids, add);
      } else {
        _editSlots = const <String?>[];
      }
    });
    if (enabled) {
      _wiggle.repeat();
    } else {
      _wiggle.stop();
      _wiggle.value = 0.0;
    }
  }

  double _wiggleAngleFor(String id) {
    final phase = (id.hashCode % 360) * (math.pi / 180.0);
    final v = _wiggle.value;
    final carrier = math.sin((v * 2 * math.pi * 2) + phase);
    return carrier * 0.014;
  }

  Widget _maybeWiggle(String id, Widget child) {
    if (!_editMode) return child;
    return AnimatedBuilder(
      animation: _wiggle,
      builder: (context, _) {
        return Transform.rotate(
          key: ValueKey('profiles_board_wiggle_$id'),
          angle: _wiggleAngleFor(id),
          child: child,
        );
      },
    );
  }

  bool _sameItems(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b) && b.toSet().containsAll(a);
  }

  int _addTileCountFor(int profileCount) {
    // Keep at least two full rows of add slots, enforce a minimum of 10
    // total board cells, and keep total cells even for the 2-column grid.
    var addCount = math.max(
      _kMinAddTileCount,
      _kMinTotalGridCells - profileCount,
    );
    if ((profileCount + addCount).isOdd) {
      addCount += 1;
    }
    return addCount;
  }

  void _moveDraggedBeforeTarget({
    required String draggedId,
    required String targetId,
  }) {
    if (draggedId == targetId) return;
    final from = _orderedIds.indexOf(draggedId);
    final to = _orderedIds.indexOf(targetId);
    if (from < 0 || to < 0) return;

    final next = List<String>.from(_orderedIds);
    final item = next.removeAt(from);
    final nextTo = from < to ? to - 1 : to;
    next.insert(nextTo, item);

    setState(() {
      _orderedIds = next;
    });

    unawaited(widget.state.reorderProfiles(next));
  }

  Future<void> _confirmDelete(UnitanaProfile profile) async {
    if (widget.state.profiles.length <= 1) return;
    final approved = await showDestructiveConfirmationSheet(
      context,
      title: DashboardCopy.profilesBoardDeleteTitle(context),
      message: DashboardCopy.profilesBoardDeleteMessage(context, profile.name),
      confirmLabel: DashboardCopy.profilesBoardDeleteConfirm(context),
    );
    if (approved != true) return;
    await widget.onDeleteProfile(profile.id);
    if (!mounted) return;
    UnitanaToast.showSuccess(
      context,
      DashboardCopy.profilesBoardDeleted(context),
    );
  }

  @override
  void dispose() {
    _wiggle.dispose();
    super.dispose();
  }

  String _flagEmoji(String? countryCode) {
    final cc = (countryCode ?? '').trim().toUpperCase();
    if (cc.length != 2) return '🏳️';
    final a = cc.codeUnitAt(0) - 65 + 0x1F1E6;
    final b = cc.codeUnitAt(1) - 65 + 0x1F1E6;
    return String.fromCharCodes([a, b]);
  }

  (Place?, Place?) _homeAndDestination(UnitanaProfile profile) {
    Place? byId(String? id) {
      if (id == null || id.trim().isEmpty) return null;
      for (final p in profile.places) {
        if (p.id == id) return p;
      }
      return null;
    }

    Place? firstByType(PlaceType type) {
      for (final p in profile.places) {
        if (p.type == type) return p;
      }
      return null;
    }

    // Prefer explicit default-place selection as "home" when available.
    final explicitHome = byId(profile.defaultPlaceId);
    if (explicitHome != null) {
      Place? explicitDestination = firstByType(PlaceType.visiting);
      if (explicitDestination?.id == explicitHome.id) {
        explicitDestination = null;
      }
      explicitDestination ??= profile.places.firstWhere(
        (p) => p.id != explicitHome.id,
        orElse: () => explicitHome,
      );
      return (explicitHome, explicitDestination);
    }

    Place? home;
    Place? destination;
    for (final p in profile.places) {
      if (p.type == PlaceType.living && home == null) home = p;
      if (p.type == PlaceType.visiting && destination == null) destination = p;
    }
    home ??= profile.places.isNotEmpty ? profile.places.first : null;
    destination ??= profile.places.length > 1 ? profile.places[1] : null;
    return (home, destination);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.state,
      builder: (context, _) {
        final byId = <String, UnitanaProfile>{
          for (final p in widget.state.profiles) p.id: p,
        };
        final ordered = _orderedIds
            .map((id) => byId[id])
            .whereType<UnitanaProfile>()
            .toList(growable: false);
        final addTileCount = _addTileCountFor(ordered.length);

        if (ordered.length != widget.state.profiles.length) {
          _syncOrderFromState();
        }
        if (_editMode) {
          _ensureEditSlots(
            ordered.map((p) => p.id).toList(growable: false),
            addTileCount,
          );
        }

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              DashboardCopy.profilesBoardTitle(context),
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (_editMode) ...[
                TextButton(
                  key: const ValueKey('profiles_board_edit_cancel'),
                  onPressed: () => _setEditMode(false),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                  ),
                  child: Text(
                    DashboardCopy.dashboardEditCancel(context),
                    style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton(
                    key: const ValueKey('profiles_board_edit_done'),
                    onPressed: () {
                      _commitEditSlots();
                      _setEditMode(false);
                      UnitanaToast.showSuccess(
                        context,
                        DashboardCopy.profilesBoardUpdated(context),
                      );
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      DashboardCopy.dashboardEditDone(context),
                      style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    key: const ValueKey('profiles_board_edit_mode'),
                    onPressed: () => _setEditMode(
                      true,
                      orderedIds: ordered
                          .map((p) => p.id)
                          .toList(growable: false),
                      addTileCount: addTileCount,
                    ),
                    child: Text(DashboardCopy.profilesBoardEditCta(context)),
                  ),
                ),
            ],
          ),
          body: SafeArea(
            child: Column(
              key: const Key('profiles_board_screen'),
              children: [
                const SizedBox(height: 8),
                Expanded(
                  child: GridView.builder(
                    key: const Key('profiles_board_grid'),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 1.0,
                        ),
                    itemCount: _editMode
                        ? _editSlots.length
                        : (ordered.length + addTileCount),
                    itemBuilder: (context, index) {
                      if (_editMode) {
                        final slotId = _editSlots[index];
                        final slotProfile = slotId == null
                            ? null
                            : byId[slotId];
                        if (slotProfile == null) {
                          return DragTarget<String>(
                            key: ValueKey('profiles_board_target_empty_$index'),
                            onWillAcceptWithDetails: (details) =>
                                details.data.trim().isNotEmpty,
                            onAcceptWithDetails: (details) {
                              _swapDraggedIntoSlot(
                                draggedId: details.data,
                                targetIndex: index,
                              );
                            },
                            builder: (context, candidateData, rejectedData) {
                              if (candidateData.isNotEmpty &&
                                  rejectedData.isNotEmpty) {
                                // no-op
                              }
                              final slotIndex = index - ordered.length < 0
                                  ? 0
                                  : index - ordered.length;
                              return _AddProfileTile(
                                onTap: widget.onAddProfile,
                                slotIndex: slotIndex,
                              );
                            },
                          );
                        }

                        final profile = slotProfile;
                        final active =
                            profile.id == widget.state.activeProfileId;

                        return DragTarget<String>(
                          key: ValueKey('profiles_board_target_${profile.id}'),
                          onWillAcceptWithDetails: (details) =>
                              details.data != profile.id,
                          onAcceptWithDetails: (details) {
                            _swapDraggedIntoSlot(
                              draggedId: details.data,
                              targetIndex: index,
                            );
                          },
                          builder: (context, candidateData, rejectedData) {
                            if (candidateData.isNotEmpty &&
                                rejectedData.isNotEmpty) {
                              // no-op
                            }

                            final feedbackTile = _ProfileTile(
                              profile: profile,
                              isActive: active,
                              isEditing: false,
                              onTap: () {},
                              onEdit: () {},
                              onDelete: () {},
                              flagEmojiForCountry: _flagEmoji,
                              homeAndDestination: _homeAndDestination,
                              dragHandle: null,
                            );

                            final dragHandle = Draggable<String>(
                              data: profile.id,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              onDragStarted: () {
                                setState(() {
                                  _draggingId = profile.id;
                                });
                              },
                              onDragEnd: (_) {
                                setState(() {
                                  _draggingId = null;
                                });
                              },
                              feedback: SizedBox(
                                width: _kDragFeedbackWidth,
                                height: _kDragFeedbackHeight,
                                child: Material(
                                  elevation: 6,
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.92,
                                    child: feedbackTile,
                                  ),
                                ),
                              ),
                              childWhenDragging: const _ProfileEditIconButton(
                                icon: Icons.drag_indicator_rounded,
                                isDragging: true,
                              ),
                              child: const _ProfileEditIconButton(
                                icon: Icons.drag_indicator_rounded,
                              ),
                            );

                            final tile = _ProfileTile(
                              profile: profile,
                              isActive: active,
                              isEditing: true,
                              onTap: () => widget.onSwitchProfile(profile.id),
                              onEdit: () => widget.onEditProfile(profile.id),
                              onDelete: () => _confirmDelete(profile),
                              flagEmojiForCountry: _flagEmoji,
                              homeAndDestination: _homeAndDestination,
                              dragHandle: dragHandle,
                            );
                            final wiggledTile = _maybeWiggle(profile.id, tile);
                            return Opacity(
                              opacity: _draggingId == profile.id ? 0.4 : 1.0,
                              child: wiggledTile,
                            );
                          },
                        );
                      }

                      if (index >= ordered.length) {
                        final addSlot = index - ordered.length;
                        return _AddProfileTile(
                          onTap: widget.onAddProfile,
                          slotIndex: addSlot,
                        );
                      }

                      final profile = ordered[index];
                      final active = profile.id == widget.state.activeProfileId;

                      return DragTarget<String>(
                        key: ValueKey('profiles_board_target_${profile.id}'),
                        onWillAcceptWithDetails: (details) =>
                            _editMode && details.data != profile.id,
                        onAcceptWithDetails: (details) {
                          _moveDraggedBeforeTarget(
                            draggedId: details.data,
                            targetId: profile.id,
                          );
                        },
                        builder: (context, candidateData, rejectedData) {
                          if (candidateData.isNotEmpty &&
                              rejectedData.isNotEmpty) {
                            // no-op (keeps strict lint happy without hiding params)
                          }
                          Widget buildTile({required Widget? dragHandle}) {
                            return _ProfileTile(
                              profile: profile,
                              isActive: active,
                              isEditing: _editMode,
                              onTap: () => widget.onSwitchProfile(profile.id),
                              onEdit: () => widget.onEditProfile(profile.id),
                              onDelete: () => _confirmDelete(profile),
                              flagEmojiForCountry: _flagEmoji,
                              homeAndDestination: _homeAndDestination,
                              dragHandle: dragHandle,
                            );
                          }

                          final feedbackTile = _ProfileTile(
                            profile: profile,
                            isActive: active,
                            isEditing: false,
                            onTap: () {},
                            onEdit: () {},
                            onDelete: () {},
                            flagEmojiForCountry: _flagEmoji,
                            homeAndDestination: _homeAndDestination,
                            dragHandle: null,
                          );

                          Widget? dragHandle;
                          if (_editMode) {
                            dragHandle = Draggable<String>(
                              data: profile.id,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              onDragStarted: () {
                                setState(() {
                                  _draggingId = profile.id;
                                });
                              },
                              onDragEnd: (_) {
                                setState(() {
                                  _draggingId = null;
                                });
                              },
                              feedback: SizedBox(
                                width: _kDragFeedbackWidth,
                                height: _kDragFeedbackHeight,
                                child: Material(
                                  elevation: 6,
                                  color: Colors.transparent,
                                  child: Opacity(
                                    opacity: 0.92,
                                    child: feedbackTile,
                                  ),
                                ),
                              ),
                              childWhenDragging: const _ProfileEditIconButton(
                                icon: Icons.drag_indicator_rounded,
                                isDragging: true,
                              ),
                              child: const _ProfileEditIconButton(
                                icon: Icons.drag_indicator_rounded,
                              ),
                            );
                          }

                          final tile = buildTile(dragHandle: dragHandle);
                          final wiggledTile = _maybeWiggle(profile.id, tile);
                          return Opacity(
                            opacity: _draggingId == profile.id ? 0.4 : 1.0,
                            child: wiggledTile,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AddProfileTile extends StatelessWidget {
  final Future<void> Function() onTap;
  final int slotIndex;

  const _AddProfileTile({required this.onTap, required this.slotIndex});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tileBg = Color.lerp(
      scheme.surfaceContainerHighest,
      scheme.surface,
      0.35,
    )!;
    final tileBorder = scheme.outline.withAlpha(150);
    final iconTone = scheme.onSurface.withAlpha(190);
    return InkWell(
      key: slotIndex == 0
          ? const Key('profiles_board_add_profile')
          : ValueKey('profiles_board_add_profile_$slotIndex'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: tileBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tileBorder),
        ),
        child: Center(
          child: Icon(Icons.add_rounded, size: 52, color: iconTone),
        ),
      ),
    );
  }
}

class _ProfileEditIconButton extends StatelessWidget {
  final IconData icon;
  final bool isDragging;

  const _ProfileEditIconButton({required this.icon, this.isDragging = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Icon(
      icon,
      size: 18,
      color: isDragging
          ? onSurface.withAlpha(90)
          : scheme.onSurfaceVariant.withAlpha(220),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final UnitanaProfile profile;
  final bool isActive;
  final bool isEditing;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final Widget? dragHandle;
  final String Function(String?) flagEmojiForCountry;
  final (Place?, Place?) Function(UnitanaProfile) homeAndDestination;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.isEditing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.dragHandle,
    required this.flagEmojiForCountry,
    required this.homeAndDestination,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textPrimary = scheme.onSurface;
    final baseTile = Color.lerp(
      scheme.surfaceContainerHighest,
      scheme.surface,
      0.18,
    )!;
    final activeTile = Color.lerp(
      baseTile,
      scheme.primary.withAlpha(24),
      0.35,
    )!;
    final tileBorder = isActive
        ? scheme.primary.withAlpha(210)
        : scheme.outline.withAlpha(145);
    final rowPanel = Color.lerp(baseTile, scheme.surface, 0.42)!;
    final rowDivider = scheme.outline.withAlpha(120);
    final badgeBg = Color.lerp(
      scheme.primary.withAlpha(64),
      scheme.secondary.withAlpha(56),
      0.25,
    )!;
    final badgeFg = scheme.onSurface;
    final homeIcon = Color.lerp(scheme.tertiary, scheme.secondary, 0.2)!;
    final destinationIcon = Color.lerp(scheme.error, scheme.tertiary, 0.35)!;

    final (home, destination) = homeAndDestination(profile);
    final homeFlag = flagEmojiForCountry(home?.countryCode);
    final destFlag = flagEmojiForCountry(destination?.countryCode);
    final homeCity =
        home?.cityName ?? DashboardCopy.profilesBoardHomeFallback(context);
    final destCity =
        destination?.cityName ??
        DashboardCopy.profilesBoardDestinationFallback(context);

    return InkWell(
      key: ValueKey('profiles_board_tile_${profile.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: isActive ? activeTile : baseTile,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: tileBorder, width: isActive ? 1.6 : 1),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxHeight < 190;
            final cellPad = tight ? 10.0 : 12.0;
            final cityFont = tight ? 12.0 : 13.0;
            final titleFont = tight ? 14.0 : 15.0;
            final iconBox = tight ? 28.0 : 32.0;
            final iconSize = tight ? 16.0 : 18.0;

            return Padding(
              padding: EdgeInsets.all(cellPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.robotoSlab(
                            fontWeight: FontWeight.w800,
                            fontSize: titleFont,
                            color: textPrimary,
                          ),
                        ),
                      ),
                      if (isActive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: badgeBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            DashboardCopy.profilesBoardActiveBadge(context),
                            style: TextStyle(
                              fontSize: 11,
                              color: badgeFg,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isEditing) ...[
                    SizedBox(height: tight ? 2 : 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          key: ValueKey('profiles_board_drag_${profile.id}'),
                          width: iconBox,
                          height: iconBox,
                          child: Center(
                            child:
                                dragHandle ??
                                Icon(
                                  Icons.drag_indicator_rounded,
                                  size: iconSize,
                                ),
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          key: ValueKey('profiles_board_edit_${profile.id}'),
                          tooltip: DashboardCopy.profilesBoardTooltipEdit(
                            context,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: BoxConstraints.tightFor(
                            width: iconBox,
                            height: iconBox,
                          ),
                          onPressed: onEdit,
                          icon: Icon(Icons.edit_rounded, size: iconSize),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          key: ValueKey('profiles_board_delete_${profile.id}'),
                          tooltip: DashboardCopy.profilesBoardTooltipDelete(
                            context,
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: BoxConstraints.tightFor(
                            width: iconBox,
                            height: iconBox,
                          ),
                          onPressed: onDelete,
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: iconSize,
                          ),
                        ),
                      ],
                    ),
                  ],
                  SizedBox(height: tight ? 4 : 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: rowPanel,
                        border: Border.all(color: rowDivider),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Icon(
                                      Icons.home_rounded,
                                      size: 14,
                                      color: homeIcon,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$homeFlag $homeCity',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: cityFont,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(height: 1, color: rowDivider),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 22,
                                    child: Icon(
                                      Icons.flight_takeoff_rounded,
                                      size: 14,
                                      color: destinationIcon,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '$destFlag $destCity',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: cityFont,
                                        color: textPrimary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
