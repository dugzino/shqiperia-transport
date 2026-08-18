import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';
import '../widgets/line_badge.dart';
import 'line_detail_screen.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  static const _repo = TransitRepository();
  String? _countryFilter; // null = all, 'kosovo', 'albania'
  TransitMode? _modeFilter;

  @override
  Widget build(BuildContext context) {
    final cities = _repo.getCities();
    var lines = _repo.getLines();

    if (_countryFilter != null) {
      final cityIds = cities
          .where((c) => c.country.name == _countryFilter)
          .map((c) => c.id)
          .toSet();
      lines = lines.where((l) => cityIds.contains(l.cityId)).toList();
    }
    if (_modeFilter != null) {
      lines = lines.where((l) => l.mode == _modeFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lines')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  selected: _countryFilter == null && _modeFilter == null,
                  onSelected: () => setState(() {
                    _countryFilter = null;
                    _modeFilter = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🇽🇰 Kosovo',
                  selected: _countryFilter == 'kosovo',
                  onSelected: () => setState(() {
                    _countryFilter = 'kosovo';
                    _modeFilter = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: '🇦🇱 Albania',
                  selected: _countryFilter == 'albania',
                  onSelected: () => setState(() {
                    _countryFilter = 'albania';
                    _modeFilter = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Intercity',
                  selected: _modeFilter == TransitMode.intercity,
                  onSelected: () => setState(() {
                    _modeFilter = TransitMode.intercity;
                    _countryFilter = null;
                  }),
                ),
              ],
            ),
          ),
          Expanded(
            child: lines.isEmpty
                ? const Center(child: Text('No lines match these filters.'))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final city = _repo.getCity(line.cityId);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          leading: LineBadge(line: line),
                          title: Text(
                            line.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              [
                                if (city != null) '${city.flag} ${city.name}',
                                line.modeLabel,
                                'every ${line.frequencyMinutes} min',
                              ].join(' · '),
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    LineDetailScreen(lineId: line.id),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      showCheckmark: false,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        fontWeight: FontWeight.w600,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: selected ? AppColors.primary : AppColors.border,
      ),
    );
  }
}
