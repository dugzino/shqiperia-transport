import 'package:flutter/material.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/transit_line.dart';
import '../../data/models/vehicle_filter.dart';
import '../../data/repositories/transit_repository.dart';
import '../../data/schedule.dart';
import '../home/edit_favourites_screen.dart';
import '../widgets/expandable_preview.dart';
import '../widgets/favorite_star_button.dart';
import '../widgets/line_badge.dart';
import '../widgets/section_header.dart';
import '../widgets/status_banner.dart';
import '../widgets/vehicle_tab_bar.dart';
import 'line_detail_screen.dart';

class LinesScreen extends StatefulWidget {
  const LinesScreen({super.key});

  @override
  State<LinesScreen> createState() => _LinesScreenState();
}

class _LinesScreenState extends State<LinesScreen> {
  static const _repo = TransitRepository();

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final favorites = FavoritesScope.maybeOf(context);
    final from = location?.position;
    final favourite = _repo.favouriteLinesMatching(
      favorites?.lineIds ?? const [],
      VehicleFilter.all,
      from: from,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Lines')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionHeader(
            title: 'Favourite lines',
            trailing: IconButton(
              tooltip: 'Edit favourites',
              onPressed: () => EditFavouritesScreen.open(
                context,
                initialTab: FavouritesTab.lines,
              ),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: favourite.isEmpty
                ? const StatusBanner(
                    icon: Icons.star_outline_rounded,
                    title: 'No favourite lines yet',
                    body: 'Tap edit to pin the lines you take often.',
                  )
                : ExpandablePreview(
                    itemCount: favourite.length,
                    itemBuilder: (context, index) {
                      final line = favourite[index];
                      return _LineCard(
                        line: line,
                        meters: from == null
                            ? null
                            : _repo.closestStopOnLine(line.id, from)?.meters,
                      );
                    },
                  ),
          ),
          _NearbyLinesSection(location: location),
        ],
      ),
    );
  }
}

class _NearbyLinesSection extends StatefulWidget {
  const _NearbyLinesSection({required this.location});

  final LocationController? location;

  @override
  State<_NearbyLinesSection> createState() => _NearbyLinesSectionState();
}

class _NearbyLinesSectionState extends State<_NearbyLinesSection>
    with SingleTickerProviderStateMixin {
  static const _repo = TransitRepository();
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: VehicleFilter.values.length, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  VehicleFilter get _filter => VehicleFilter.values[_tabs.index];
  LocationController? get location => widget.location;

  List<({TransitLine line, double meters})> get nearby {
    final from = location?.position;
    if (from == null) return const [];
    return _repo.nearbyLines(from, filter: _filter);
  }

  @override
  Widget build(BuildContext context) {
    final searching = location?.status == LocationStatus.requesting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nearby lines (<1km)',
          trailing: IconButton(
            tooltip: 'Refresh nearby lines',
            onPressed: searching || location == null
                ? null
                : location!.requestAccess,
            icon: searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        VehicleTabBar(controller: _tabs),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
          child: _body(),
        ),
      ],
    );
  }

  Widget _body() {
    final loc = location;
    if (loc == null) {
      return const StatusBanner(
        icon: Icons.near_me_rounded,
        title: 'See nearby lines',
        body: 'Allow location to see lines with a stop within 1 km.',
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isNotEmpty) {
      return ExpandablePreview(
        itemCount: nearby.length,
        itemBuilder: (context, index) {
          final item = nearby[index];
          return _LineCard(line: item.line, meters: item.meters);
        },
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isEmpty) {
      return const StatusBanner(
        icon: Icons.near_me_disabled_rounded,
        title: 'No lines nearby',
        body: 'Nothing in this category has a stop within 1 km.',
      );
    }

    if (loc.status == LocationStatus.requesting) {
      return const StatusBanner(
        icon: Icons.my_location_rounded,
        title: 'Finding nearby lines…',
        body: 'Using your location for the closest lines.',
      );
    }

    final deniedForever = loc.status == LocationStatus.deniedForever;
    final disabled = loc.status == LocationStatus.disabled;
    return StatusBanner(
      icon: Icons.near_me_rounded,
      title: disabled ? 'Turn on location' : 'See nearby lines',
      body: disabled
          ? 'Location services are off. Turn them on to see nearby lines.'
          : deniedForever
              ? 'Location is blocked. Enable it in settings to see nearby lines.'
              : 'Allow location to see lines with a stop within 1 km.',
      actionLabel: disabled || deniedForever ? 'Open settings' : 'Allow location',
      onAction: () {
        if (disabled || deniedForever) {
          loc.openSettings();
        } else {
          loc.requestAccess();
        }
      },
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.line, this.meters});

  final TransitLine line;
  final double? meters;

  @override
  Widget build(BuildContext context) {
    const repo = TransitRepository();
    final city = repo.getCity(line.cityId);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: LineBadge(line: line),
        title: Text(
          line.name,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              if (city != null) city.name,
              line.modeLabel,
              if (meters != null) TransitSchedule.distanceLabel(meters!),
            ].join(' · '),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FavoriteStarButton(lineId: line.id),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => LineDetailScreen(lineId: line.id),
            ),
          );
        },
      ),
    );
  }
}
