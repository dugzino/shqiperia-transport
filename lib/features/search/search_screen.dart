import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/transit_repository.dart';
import '../lines/line_detail_screen.dart';
import '../widgets/line_badge.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  static const _repo = TransitRepository();
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lines = _repo.searchLines(_query);
    final stops = _repo.searchStops(_query);
    final cities = _repo.searchCities(_query);
    final hasQuery = _query.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Lines, stops, cities…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _controller.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              children: [
                if (!hasQuery) ...[
                  Text(
                    'Try searching',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tip in [
                        'Pristina',
                        'Line 1',
                        'Tirana',
                        'Intercity',
                        'Germia',
                      ])
                        ActionChip(
                          label: Text(tip),
                          onPressed: () {
                            _controller.text = tip;
                            setState(() => _query = tip);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
                if (cities.isNotEmpty) ...[
                  _SectionLabel('Cities'),
                  const SizedBox(height: 8),
                  ...cities.map(
                    (city) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.primary.withValues(alpha: 0.1),
                          child: Text(city.flag),
                        ),
                        title: Text(
                          city.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${city.nameLocal} · ${city.countryLabel}',
                        ),
                        trailing: Text(
                          '${city.lineCount} lines',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (lines.isNotEmpty) ...[
                  _SectionLabel('Lines'),
                  const SizedBox(height: 8),
                  ...lines.map(
                    (line) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: LineBadge(line: line, compact: true),
                        title: Text(
                          line.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${line.modeLabel} · every ${line.frequencyMinutes} min',
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
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (stops.isNotEmpty) ...[
                  _SectionLabel('Stops'),
                  const SizedBox(height: 8),
                  ...stops.map(
                    (stop) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppColors.secondarySoft,
                          child: Icon(
                            Icons.hail_rounded,
                            color: AppColors.secondary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          stop.name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${stop.lineIds.length} line(s)',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
                if (hasQuery &&
                    cities.isEmpty &&
                    lines.isEmpty &&
                    stops.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 48),
                    child: Column(
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No results for “$_query”',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w800,
          ),
    );
  }
}
