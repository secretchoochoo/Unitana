import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/dashboard_copy.dart';

@immutable
class SettingsLicensesPage extends StatefulWidget {
  final String applicationName;
  final String applicationLegalese;

  const SettingsLicensesPage({
    super.key,
    required this.applicationName,
    required this.applicationLegalese,
  });

  @override
  State<SettingsLicensesPage> createState() => _SettingsLicensesPageState();
}

class _SettingsLicensesPageState extends State<SettingsLicensesPage> {
  final TextEditingController _queryController = TextEditingController();
  String _query = '';

  late final Future<List<_LicensePackageGroup>> _packagesFuture =
      _loadLicensePackages();

  Future<List<_LicensePackageGroup>> _loadLicensePackages() async {
    final byPackage = <String, List<String>>{};
    await for (final entry in LicenseRegistry.licenses) {
      final buffer = StringBuffer();
      for (final p in entry.paragraphs) {
        final line = p.text.trimRight();
        if (line.isEmpty) {
          buffer.writeln();
        } else {
          buffer.writeln(line);
        }
      }
      final text = buffer.toString().trim();
      if (text.isEmpty) continue;
      for (final package in entry.packages) {
        final key = package.trim();
        if (key.isEmpty) continue;
        final list = byPackage.putIfAbsent(key, () => <String>[]);
        if (!list.contains(text)) list.add(text);
      }
    }

    final groups =
        byPackage.entries
            .map(
              (e) => _LicensePackageGroup(
                package: e.key,
                entries: e.value,
                summary: _deriveSummary(e.value),
              ),
            )
            .toList(growable: false)
          ..sort((a, b) => a.package.compareTo(b.package));
    return groups;
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  static String _deriveSummary(List<String> entries) {
    if (entries.isEmpty) return '';
    final haystack = entries.join('\n').toLowerCase();
    if (haystack.contains('mit license')) return 'MIT';
    if (haystack.contains('apache license')) return 'Apache';
    if (haystack.contains('bsd')) return 'BSD';
    if (haystack.contains('mozilla public license')) return 'MPL';
    if (haystack.contains('gnu lesser general public license')) return 'LGPL';
    if (haystack.contains('gnu general public license')) return 'GPL';
    return '';
  }

  Future<void> _openRawLicensePage() async {
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => LicensePage(
          key: const ValueKey('settings_licenses_raw_page'),
          applicationName: widget.applicationName,
          applicationLegalese: widget.applicationLegalese,
        ),
        settings: const RouteSettings(name: 'settings_licenses_raw_route'),
      ),
    );
  }

  Future<void> _showPackageDetails(_LicensePackageGroup group) async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final theme = Theme.of(context);
        return FractionallySizedBox(
          heightFactor: 0.9,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    group.package,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DashboardCopy.settingsLicensesEntries(context)}: ${group.entries.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.separated(
                      itemCount: group.entries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, i) => DecoratedBox(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withAlpha(64),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: SelectableText(
                            group.entries[i],
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: const ValueKey('settings_licenses_page_scaffold'),
      appBar: AppBar(title: Text(DashboardCopy.settingsLicensesTitle(context))),
      body: FutureBuilder<List<_LicensePackageGroup>>(
        future: _packagesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          final packages = snapshot.data ?? const <_LicensePackageGroup>[];
          final q = _query.trim().toLowerCase();
          final visible = q.isEmpty
              ? packages
              : packages
                    .where((p) => p.package.toLowerCase().contains(q))
                    .toList(growable: false);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withAlpha(
                    72,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DashboardCopy.settingsLicensesReadableTitle(context),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DashboardCopy.settingsLicensesReadableBody(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(
                              '${DashboardCopy.settingsLicensesPackages(context)}: ${packages.length}',
                            ),
                          ),
                          if (visible.length != packages.length)
                            Chip(
                              label: Text(
                                '${DashboardCopy.settingsLicensesViewDetails(context)}: ${visible.length}',
                              ),
                            ),
                          OutlinedButton.icon(
                            key: const ValueKey('settings_licenses_open_raw'),
                            onPressed: _openRawLicensePage,
                            icon: const Icon(Icons.article_outlined, size: 16),
                            label: Text(
                              DashboardCopy.settingsLicensesOpenRaw(context),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const ValueKey('settings_licenses_search'),
                controller: _queryController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded),
                  hintText: DashboardCopy.settingsLicensesSearchHint(context),
                  suffixIcon: _query.trim().isEmpty
                      ? null
                      : IconButton(
                          tooltip:
                              DashboardCopy.settingsLicensesClearSearchTooltip(
                                context,
                              ),
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _queryController.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 12),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    DashboardCopy.settingsLicensesNoMatchingPackage(context),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              for (final package in visible)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ExpansionTile(
                    key: ValueKey('settings_license_group_${package.package}'),
                    tilePadding: const EdgeInsets.symmetric(horizontal: 10),
                    childrenPadding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    collapsedShape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: theme.colorScheme.outlineVariant),
                    ),
                    title: Text(
                      package.package,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Text(
                      '${package.summary.isEmpty ? DashboardCopy.settingsLicensesSummaryFallback(context) : package.summary} • ${package.entries.length} ${DashboardCopy.settingsLicensesEntries(context)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: OutlinedButton.icon(
                          key: ValueKey(
                            'settings_license_view_${package.package}',
                          ),
                          onPressed: () => _showPackageDetails(package),
                          icon: const Icon(Icons.visibility_outlined, size: 16),
                          label: Text(
                            DashboardCopy.settingsLicensesViewDetails(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

@immutable
class _LicensePackageGroup {
  final String package;
  final List<String> entries;
  final String summary;

  const _LicensePackageGroup({
    required this.package,
    required this.entries,
    required this.summary,
  });
}
