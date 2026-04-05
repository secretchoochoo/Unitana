import 'package:flutter/material.dart';

class SearchableOptionPickerEntry<T> {
  final T value;
  final String title;
  final String? subtitle;
  final List<String> searchTokens;
  final Key? key;

  const SearchableOptionPickerEntry({
    required this.value,
    required this.title,
    this.subtitle,
    this.searchTokens = const <String>[],
    this.key,
  });
}

class SearchableOptionPickerSheet<T> extends StatefulWidget {
  final String title;
  final String closeTooltip;
  final String searchHint;
  final String noMatchesText;
  final String selectedHeader;
  final String suggestedHeader;
  final String allHeader;
  final T? selectedValue;
  final List<T> suggestedValues;
  final List<SearchableOptionPickerEntry<T>> options;
  final Key? listKey;
  final Key? searchFieldKey;

  const SearchableOptionPickerSheet({
    super.key,
    required this.title,
    required this.closeTooltip,
    required this.searchHint,
    required this.noMatchesText,
    required this.selectedHeader,
    required this.suggestedHeader,
    required this.allHeader,
    required this.options,
    this.selectedValue,
    this.suggestedValues = const [],
    this.listKey,
    this.searchFieldKey,
  });

  @override
  State<SearchableOptionPickerSheet<T>> createState() =>
      _SearchableOptionPickerSheetState<T>();
}

class _SearchableOptionPickerSheetState<T>
    extends State<SearchableOptionPickerSheet<T>> {
  String _query = '';

  String _normalize(String value) => value.trim().toLowerCase();

  bool _matches(SearchableOptionPickerEntry<T> entry, String query) {
    final normalizedQuery = _normalize(query);
    if (normalizedQuery.isEmpty) return true;
    final haystack = <String>[
      entry.title,
      if (entry.subtitle != null) entry.subtitle!,
      ...entry.searchTokens,
    ].map(_normalize).join(' ');
    return haystack.contains(normalizedQuery);
  }

  SearchableOptionPickerEntry<T>? _findByValue(T value) {
    for (final option in widget.options) {
      if (option.value == value) return option;
    }
    return null;
  }

  Widget _sectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildTile(
    BuildContext context,
    SearchableOptionPickerEntry<T> entry, {
    required bool isSelected,
  }) {
    return ListTile(
      key: entry.key,
      title: Text(
        entry.title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: (entry.subtitle == null || entry.subtitle!.trim().isEmpty)
          ? null
          : Text(entry.subtitle!),
      trailing: isSelected
          ? Icon(
              Icons.check_rounded,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: () => Navigator.of(context).pop(entry.value),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((entry) => _matches(entry, _query))
        .toList(growable: false);
    final selected = widget.selectedValue == null
        ? null
        : _findByValue(widget.selectedValue as T);

    final suggested = <SearchableOptionPickerEntry<T>>[];
    final seen = <T>{
      if (widget.selectedValue != null) widget.selectedValue as T,
    };
    for (final value in widget.suggestedValues) {
      if (seen.contains(value)) continue;
      final entry = _findByValue(value);
      if (entry == null) continue;
      suggested.add(entry);
      seen.add(value);
    }

    final remaining = widget.options
        .where((entry) => !seen.contains(entry.value))
        .toList(growable: false);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: widget.closeTooltip,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              key: widget.searchFieldKey,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                isDense: true,
              ),
            ),
          ),
          Flexible(
            child: ListView(
              key: widget.listKey,
              shrinkWrap: true,
              children: [
                if (_query.trim().isNotEmpty) ...[
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Text(
                        widget.noMatchesText,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else ...[
                    _sectionLabel(context, widget.allHeader),
                    for (final entry in filtered)
                      _buildTile(
                        context,
                        entry,
                        isSelected: entry.value == widget.selectedValue,
                      ),
                  ],
                ] else ...[
                  if (selected != null) ...[
                    _sectionLabel(context, widget.selectedHeader),
                    _buildTile(context, selected, isSelected: true),
                  ],
                  if (suggested.isNotEmpty) ...[
                    _sectionLabel(context, widget.suggestedHeader),
                    for (final entry in suggested)
                      _buildTile(context, entry, isSelected: false),
                  ],
                  if (remaining.isNotEmpty) ...[
                    _sectionLabel(context, widget.allHeader),
                    for (final entry in remaining)
                      _buildTile(context, entry, isSelected: false),
                  ],
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
