import 'package:flutter/material.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/stop.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';
import '../widgets/line_badge.dart';
import '../widgets/section_header.dart';

class EditFavouritesScreen extends StatelessWidget {
  const EditFavouritesScreen({super.key});

  static const _repo = TransitRepository();

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => const EditFavouritesScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.maybeOf(context);
    final lines = <TransitLine>[
      for (final id in favorites?.lineIds ?? const <String>[])
        ?_repo.getLine(id),
    ];
    final stops = <Stop>[
      for (final id in favorites?.stopIds ?? const <String>[])
        ?_repo.getStop(id),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit favourites'),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          SectionHeader(
            title: 'Favourite lines',
            actionLabel: 'Add line',
            onAction: () => _AddFavouriteLineScreen.open(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: lines.isEmpty
                ? const _EmptyFavouritesHint(
                    message: 'No favourite lines yet. Add the routes you take often.',
                  )
                : Column(
                    children: [
                      for (final line in lines) ...[
                        _FavouriteLineTile(
                          line: line,
                          cityName: _repo.getCity(line.cityId)?.name,
                          onRemove: favorites == null
                              ? null
                              : () => favorites.removeLine(line.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
          SectionHeader(
            title: 'Favourite stops',
            actionLabel: 'Add stop',
            onAction: () => _AddFavouriteStopScreen.open(context),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: stops.isEmpty
                ? const _EmptyFavouritesHint(
                    message: 'No favourite stops yet. Pin a stop to find it quickly.',
                  )
                : Column(
                    children: [
                      for (final stop in stops) ...[
                        _FavouriteStopTile(
                          stop: stop,
                          onRemove: favorites == null
                              ? null
                              : () => favorites.removeStop(stop.id),
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _EmptyFavouritesHint extends StatelessWidget {
  const _EmptyFavouritesHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: const TextStyle(
            color: AppColors.textSecondary,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _FavouriteLineTile extends StatelessWidget {
  const _FavouriteLineTile({
    required this.line,
    required this.onRemove,
    this.cityName,
  });

  final TransitLine line;
  final String? cityName;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        leading: LineBadge(line: line),
        title: Text(
          line.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          [
            if (cityName != null) cityName,
            line.modeLabel,
            'every ${line.frequencyMinutes} min',
          ].join(' · '),
        ),
        trailing: IconButton(
          tooltip: 'Remove line',
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
      ),
    );
  }
}

class _FavouriteStopTile extends StatelessWidget {
  const _FavouriteStopTile({
    required this.stop,
    required this.onRemove,
  });

  final Stop stop;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
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
        subtitle: Text('${stop.lineIds.length} line(s)'),
        trailing: IconButton(
          tooltip: 'Remove stop',
          onPressed: onRemove,
          icon: const Icon(Icons.remove_circle_outline_rounded),
        ),
      ),
    );
  }
}

class _AddFavouriteLineScreen extends StatefulWidget {
  const _AddFavouriteLineScreen();

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _AddFavouriteLineScreen(),
      ),
    );
  }

  @override
  State<_AddFavouriteLineScreen> createState() =>
      _AddFavouriteLineScreenState();
}

class _AddFavouriteLineScreenState extends State<_AddFavouriteLineScreen> {
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
    final favorites = FavoritesScope.maybeOf(context);
    final favourited = favorites?.lineIds.toSet() ?? const <String>{};
    final lines = _repo
        .searchLines(_query)
        .where((line) => !favourited.contains(line.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add a line')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search lines',
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
            child: lines.isEmpty
                ? const _PickerEmpty(
                    message: 'No more lines to add.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final line = lines[index];
                      final city = _repo.getCity(line.cityId);
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          leading: LineBadge(line: line),
                          title: Text(
                            line.name,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (city != null) city.name,
                              line.modeLabel,
                              'every ${line.frequencyMinutes} min',
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.add_rounded),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            favorites?.addLine(line.id);
                            navigator.pop();
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

class _AddFavouriteStopScreen extends StatefulWidget {
  const _AddFavouriteStopScreen();

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const _AddFavouriteStopScreen(),
      ),
    );
  }

  @override
  State<_AddFavouriteStopScreen> createState() =>
      _AddFavouriteStopScreenState();
}

class _AddFavouriteStopScreenState extends State<_AddFavouriteStopScreen> {
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
    final favorites = FavoritesScope.maybeOf(context);
    final favourited = favorites?.stopIds.toSet() ?? const <String>{};
    final stops = _repo
        .searchStops(_query)
        .where((stop) => !favourited.contains(stop.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Add a stop')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search stops',
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
            child: stops.isEmpty
                ? const _PickerEmpty(
                    message: 'No more stops to add.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: stops.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final stop = stops[index];
                      return Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
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
                          subtitle: Text('${stop.lineIds.length} line(s)'),
                          trailing: const Icon(Icons.add_rounded),
                          onTap: () {
                            final navigator = Navigator.of(context);
                            favorites?.addStop(stop.id);
                            navigator.pop();
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

class _PickerEmpty extends StatelessWidget {
  const _PickerEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
      ),
    );
  }
}
