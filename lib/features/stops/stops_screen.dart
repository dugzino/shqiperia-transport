import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/nearby_stop.dart';
import '../../data/models/stop.dart';
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

class StopsScreen extends StatefulWidget {
  const StopsScreen({super.key});

  @override
  State<StopsScreen> createState() => _StopsScreenState();
}

class _StopsScreenState extends State<StopsScreen> {
  static const _repo = TransitRepository();

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final favorites = FavoritesScope.maybeOf(context);
    final from = location?.position;
    final favourite = _repo.favouriteStopsMatching(
      favorites?.stopIds ?? const [],
      VehicleFilter.all,
      from: from,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Stops')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SectionHeader(
            title: 'Favourite stops',
            trailing: IconButton(
              tooltip: 'Edit favourites',
              onPressed: () => EditFavouritesScreen.open(context),
              icon: const Icon(Icons.edit_rounded),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: favourite.isEmpty
                ? const StatusBanner(
                    icon: Icons.star_outline_rounded,
                    title: 'No favourite stops yet',
                    body: 'Tap edit to pin the stops you use often.',
                  )
                : ExpandablePreview(
                    itemCount: favourite.length,
                    itemBuilder: (context, index) {
                      final stop = favourite[index];
                      final meters = from == null
                          ? null
                          : const Distance().as(
                              LengthUnit.Meter,
                              from,
                              stop.location,
                            );
                      return _StopCard(stop: stop, meters: meters);
                    },
                  ),
          ),
          _NearbyStopsSection(location: location),
        ],
      ),
    );
  }
}

class _NearbyStopsSection extends StatefulWidget {
  const _NearbyStopsSection({required this.location});

  final LocationController? location;

  @override
  State<_NearbyStopsSection> createState() => _NearbyStopsSectionState();
}

class _NearbyStopsSectionState extends State<_NearbyStopsSection>
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

  List<NearbyStop> get nearby {
    final from = location?.position;
    if (from == null) return const [];
    return _repo.nearbyStopsMatching(from, _filter);
  }

  @override
  Widget build(BuildContext context) {
    final searching = location?.status == LocationStatus.requesting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nearby stops (<1km)',
          trailing: IconButton(
            tooltip: 'Refresh nearby stops',
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
        title: 'See nearby stops',
        body: 'Allow location to see stops within 1 km.',
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isNotEmpty) {
      return ExpandablePreview(
        itemCount: nearby.length,
        itemBuilder: (context, index) {
          final item = nearby[index];
          return _StopCard(stop: item.stop, meters: item.meters);
        },
      );
    }

    if (loc.status == LocationStatus.granted && nearby.isEmpty) {
      return const StatusBanner(
        icon: Icons.near_me_disabled_rounded,
        title: 'No stops nearby',
        body: 'Nothing in this category is within 1 km.',
      );
    }

    if (loc.status == LocationStatus.requesting) {
      return const StatusBanner(
        icon: Icons.my_location_rounded,
        title: 'Finding nearby stops…',
        body: 'Using your location for the closest stops.',
      );
    }

    final deniedForever = loc.status == LocationStatus.deniedForever;
    final disabled = loc.status == LocationStatus.disabled;
    return StatusBanner(
      icon: Icons.near_me_rounded,
      title: disabled ? 'Turn on location' : 'See nearby stops',
      body: disabled
          ? 'Location services are off. Turn them on to see nearby stops.'
          : deniedForever
              ? 'Location is blocked. Enable it in settings to see nearby stops.'
              : 'Allow location to see stops within 1 km.',
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

class _StopCard extends StatelessWidget {
  const _StopCard({required this.stop, this.meters});

  final Stop stop;
  final double? meters;

  @override
  Widget build(BuildContext context) {
    const repo = TransitRepository();
    final lines = [
      for (final id in stop.lineIds) ?repo.getLine(id),
    ];
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                [
                  if (meters != null) TransitSchedule.distanceLabel(meters!),
                  '${stop.lineIds.length} line(s)',
                ].join(' · '),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              if (lines.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final line in lines.take(6))
                      LineBadge(line: line, compact: true),
                  ],
                ),
              ],
            ],
          ),
        ),
        trailing: FavoriteStarButton(stopId: stop.id),
      ),
    );
  }
}
