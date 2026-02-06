import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../app/app_state.dart';
import '../../../models/place.dart';
import '../../../theme/dracula_palette.dart';
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

class _ProfilesBoardScreenState extends State<ProfilesBoardScreen> {
  static const int _kMinAddTileCount = 4;
  static const double _kEditAppBarActionFontSize = 14;

  bool _editMode = false;
  List<String> _orderedIds = const <String>[];
  String? _draggingId;

  @override
  void initState() {
    super.initState();
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

  bool _sameItems(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    return a.toSet().containsAll(b) && b.toSet().containsAll(a);
  }

  int _addTileCountFor(int profileCount) {
    // Keep at least two full rows of add slots, and keep total grid cells even
    // so the 2-column board does not end with an orphan final tile.
    var addCount = _kMinAddTileCount;
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
      title: 'Delete profile?',
      message: 'Delete "${profile.name}"? This cannot be undone.',
      confirmLabel: 'Delete',
    );
    if (approved != true) return;
    await widget.onDeleteProfile(profile.id);
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

        return Scaffold(
          appBar: AppBar(
            centerTitle: true,
            title: Text(
              'Profiles',
              style: GoogleFonts.robotoSlab(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (_editMode) ...[
                TextButton(
                  key: const ValueKey('profiles_board_edit_cancel'),
                  onPressed: () {
                    setState(() {
                      _editMode = false;
                    });
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: const Size(0, 36),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: TextButton(
                    key: const ValueKey('profiles_board_edit_done'),
                    onPressed: () {
                      setState(() {
                        _editMode = false;
                      });
                    },
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 36),
                    ),
                    child: const Text(
                      'Done',
                      style: TextStyle(fontSize: _kEditAppBarActionFontSize),
                    ),
                  ),
                ),
              ] else
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TextButton(
                    key: const ValueKey('profiles_board_edit_mode'),
                    onPressed: () {
                      setState(() {
                        _editMode = true;
                      });
                    },
                    child: const Text('✏ Edit'),
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
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 0.9,
                        ),
                    itemCount: ordered.length + addTileCount,
                    itemBuilder: (context, index) {
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
                          final tile = _ProfileTile(
                            profile: profile,
                            isActive: active,
                            isEditing: _editMode,
                            onTap: () => widget.onSwitchProfile(profile.id),
                            onEdit: () => widget.onEditProfile(profile.id),
                            onDelete: () => _confirmDelete(profile),
                            flagEmojiForCountry: _flagEmoji,
                            homeAndDestination: _homeAndDestination,
                          );

                          if (!_editMode) return tile;

                          return LongPressDraggable<String>(
                            data: profile.id,
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
                              width: 160,
                              child: Material(
                                elevation: 6,
                                color: Colors.transparent,
                                child: Opacity(opacity: 0.92, child: tile),
                              ),
                            ),
                            childWhenDragging: Opacity(
                              opacity: _draggingId == profile.id ? 0.4 : 1.0,
                              child: tile,
                            ),
                            child: tile,
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
    return InkWell(
      key: slotIndex == 0
          ? const Key('profiles_board_add_profile')
          : ValueKey('profiles_board_add_profile_$slotIndex'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: DraculaPalette.currentLine.withAlpha(140),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: DraculaPalette.comment.withAlpha(120)),
        ),
        child: Center(
          child: Icon(
            Icons.add_rounded,
            size: 54,
            color: DraculaPalette.foreground.withAlpha(230),
          ),
        ),
      ),
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
  final String Function(String?) flagEmojiForCountry;
  final (Place?, Place?) Function(UnitanaProfile) homeAndDestination;

  const _ProfileTile({
    required this.profile,
    required this.isActive,
    required this.isEditing,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.flagEmojiForCountry,
    required this.homeAndDestination,
  });

  @override
  Widget build(BuildContext context) {
    final (home, destination) = homeAndDestination(profile);
    final homeFlag = flagEmojiForCountry(home?.countryCode);
    final destFlag = flagEmojiForCountry(destination?.countryCode);
    final homeCity = home?.cityName ?? 'Home';
    final destCity = destination?.cityName ?? 'Destination';

    return InkWell(
      key: ValueKey('profiles_board_tile_${profile.id}'),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
          color: DraculaPalette.currentLine.withAlpha(180),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? DraculaPalette.purple.withAlpha(210)
                : DraculaPalette.comment.withAlpha(120),
            width: isActive ? 1.6 : 1,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final tight = constraints.maxHeight < 190;
            final cellPad = tight ? 10.0 : 12.0;
            final cityFont = tight ? 12.0 : 13.0;
            final titleFont = tight ? 15.0 : 16.0;
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
                            color: DraculaPalette.purple.withAlpha(70),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Active',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                    ],
                  ),
                  if (isEditing) ...[
                    SizedBox(height: tight ? 2 : 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          key: ValueKey('profiles_board_drag_${profile.id}'),
                          tooltip: 'Drag profile',
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.all(4),
                          constraints: BoxConstraints.tightFor(
                            width: iconBox,
                            height: iconBox,
                          ),
                          onPressed: () {},
                          icon: Icon(
                            Icons.drag_indicator_rounded,
                            size: iconSize,
                          ),
                        ),
                        const SizedBox(width: 2),
                        IconButton(
                          key: ValueKey('profiles_board_edit_${profile.id}'),
                          tooltip: 'Edit profile',
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
                          tooltip: 'Delete profile',
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
                        border: Border.all(
                          color: DraculaPalette.comment.withAlpha(100),
                        ),
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
                                  const SizedBox(
                                    width: 22,
                                    child: Icon(
                                      Icons.home_rounded,
                                      size: 14,
                                      color: DraculaPalette.green,
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
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            height: 1,
                            color: DraculaPalette.comment.withAlpha(100),
                          ),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              child: Row(
                                children: [
                                  const SizedBox(
                                    width: 22,
                                    child: Icon(
                                      Icons.flight_takeoff_rounded,
                                      size: 14,
                                      color: DraculaPalette.orange,
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
