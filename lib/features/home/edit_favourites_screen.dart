import 'package:flutter/material.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/saved_address.dart';
import '../../data/models/stop.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';
import '../addresses/save_address_screen.dart';
import '../widgets/line_badge.dart';
import '../widgets/stop_mode_avatar.dart';

enum FavouritesTab { lines, stops, places }

class EditFavouritesScreen extends StatefulWidget {
  const EditFavouritesScreen({
    super.key,
    this.initialTab = FavouritesTab.lines,
  });

  final FavouritesTab initialTab;

  static const _repo = TransitRepository();

  static Future<void> open(
    BuildContext context, {
    FavouritesTab initialTab = FavouritesTab.lines,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => EditFavouritesScreen(initialTab: initialTab),
      ),
    );
  }

  @override
  State<EditFavouritesScreen> createState() => _EditFavouritesScreenState();
}

class _EditFavouritesScreenState extends State<EditFavouritesScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(
      length: FavouritesTab.values.length,
      vsync: this,
      initialIndex: widget.initialTab.index,
    );
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  FavouritesTab get _currentTab => FavouritesTab.values[_tabs.index];

  String get _addLabel => switch (_currentTab) {
        FavouritesTab.lines => 'Add line',
        FavouritesTab.stops => 'Add stop',
        FavouritesTab.places => 'Add place',
      };

  void _addCurrent() {
    switch (_currentTab) {
      case FavouritesTab.lines:
        _AddFavouriteLineScreen.open(context);
      case FavouritesTab.stops:
        _AddFavouriteStopScreen.open(context);
      case FavouritesTab.places:
        SaveAddressScreen.open(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final favorites = FavoritesScope.maybeOf(context);
    final lines = <TransitLine>[
      for (final id in favorites?.lineIds ?? const <String>[])
        ?EditFavouritesScreen._repo.getLine(id),
    ];
    final stops = <Stop>[
      for (final id in favorites?.stopIds ?? const <String>[])
        ?EditFavouritesScreen._repo.getStop(id),
    ];
    final addresses =
        favorites?.displayAddresses ?? SavedAddress.emptyPresets;

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 56,
        title: const Text('Edit favourites'),
        actions: [
          TextButton(
            onPressed: _addCurrent,
            child: Text(
              _addLabel,
              style: const TextStyle(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.textOnPrimary,
          unselectedLabelColor: AppColors.textOnPrimary.withValues(alpha: 0.7),
          indicatorColor: AppColors.textOnPrimary,
          indicatorWeight: 3,
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(text: 'Lines'),
            Tab(text: 'Stops'),
            Tab(text: 'Places'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _FavouritesList(
            isEmpty: lines.isEmpty,
            emptyMessage:
                'No favourite lines yet. Add the routes you take often.',
            children: [
              for (final line in lines)
                _FavouriteLineTile(
                  line: line,
                  cityName: EditFavouritesScreen._repo.getCity(line.cityId)?.name,
                  onRemove: favorites == null
                      ? null
                      : () => favorites.removeLine(line.id),
                ),
            ],
          ),
          _FavouritesList(
            isEmpty: stops.isEmpty,
            emptyMessage:
                'No favourite stops yet. Pin a stop to find it quickly.',
            children: [
              for (final stop in stops)
                _FavouriteStopTile(
                  stop: stop,
                  onRemove: favorites == null
                      ? null
                      : () => favorites.removeStop(stop.id),
                ),
            ],
          ),
          _FavouritesList(
            children: [
              for (final address in addresses)
                _SavedAddressTile(
                  address: address,
                  onEdit: () => SaveAddressScreen.open(
                    context,
                    existing: address,
                  ),
                  onClear: favorites == null || !address.isSet
                      ? null
                      : () => favorites.removeAddress(address.id),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FavouritesList extends StatelessWidget {
  const _FavouritesList({
    required this.children,
    this.isEmpty = false,
    this.emptyMessage,
  });

  final List<Widget> children;
  final bool isEmpty;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (isEmpty && emptyMessage != null) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          _EmptyFavouritesHint(message: emptyMessage!),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: children.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) => children[index],
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

class _SavedAddressTile extends StatelessWidget {
  const _SavedAddressTile({
    required this.address,
    required this.onEdit,
    this.onClear,
  });

  final SavedAddress address;
  final VoidCallback onEdit;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 6, 4, 6),
        leading: CircleAvatar(
          backgroundColor: AppColors.secondarySoft,
          child: Icon(address.icon, color: AppColors.secondary, size: 20),
        ),
        title: Text(
          address.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(address.subtitle),
        onTap: onEdit,
        trailing: onClear == null
            ? const Icon(Icons.chevron_right_rounded)
            : IconButton(
                tooltip: address.isPreset ? 'Clear address' : 'Remove place',
                onPressed: onClear,
                icon: const Icon(Icons.remove_circle_outline_rounded),
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
            line.frequencyLabel,
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
        leading: StopModeAvatar.forStop(stop),
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
                              line.frequencyLabel,
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
                          leading: StopModeAvatar.forStop(stop),
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
