import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../core/favorites/favorites_controller.dart';
import '../../core/favorites/favorites_scope.dart';
import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/city.dart';
import '../../data/models/nearby_stop.dart';
import '../../data/models/stop.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';
import '../../data/schedule.dart';
import '../widgets/favorite_star_button.dart';
import '../widgets/line_badge.dart';
import '../widgets/section_header.dart';
import '../lines/line_detail_screen.dart';
import 'edit_favourites_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const _repo = TransitRepository();

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    final nearby = location?.position == null
        ? const <NearbyStop>[]
        : _repo.nearbyStops(location!.position!, limit: null);
    final favorites = FavoritesScope.maybeOf(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 88,
        title: const Padding(
          padding: EdgeInsets.only(top: 10),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Soar Albania'),
            SizedBox(height: 2),
            Text(
              'Buses & routes across Kosova and Albania',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          ),
        ),
      ),
      body: CustomScrollView(
        slivers: [
            SliverToBoxAdapter(
              child: _FavouriteLinesSection(
                repo: _repo,
                favorites: favorites,
                from: location?.position,
              ),
            ),
            if (location != null)
              SliverToBoxAdapter(
                child: _LocationSection(
                  location: location,
                  nearby: nearby,
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
      ),
    );
  }
}

class _FavouriteLinesSection extends StatelessWidget {
  const _FavouriteLinesSection({
    required this.repo,
    required this.favorites,
    this.from,
  });

  final TransitRepository repo;
  final FavoritesController? favorites;
  final LatLng? from;

  @override
  Widget build(BuildContext context) {
    final favouriteIds = favorites?.lineIds ?? const <String>[];
    final hasFavourites = favouriteIds.isNotEmpty;
    final lines = from == null
        ? const <TransitLine>[]
        : repo.closestFavouriteLines(favouriteIds, from!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Favourite lines',
          trailing: IconButton(
            tooltip: 'Edit favourites',
            onPressed: () => EditFavouritesScreen.open(context),
            icon: const Icon(Icons.edit_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: !hasFavourites
              ? const _LocationBanner(
                  icon: Icons.star_outline_rounded,
                  title: 'No favourite lines yet',
                  body:
                      'Tap edit to pin lines here with the next departures.',
                )
              : from == null
                  ? const _LocationBanner(
                      icon: Icons.near_me_rounded,
                      title: 'Find closest favourites',
                      body:
                          'Allow location to show the 3 closest favourite lines within 10 km.',
                    )
                  : lines.isEmpty
                      ? const _LocationBanner(
                          icon: Icons.near_me_disabled_rounded,
                          title: 'No favourite lines nearby',
                          body:
                              'None of your favourite lines are within 10 km.',
                        )
                      : Column(
                          children: [
                            for (final line in lines) ...[
                              _FavouriteLineCard(
                                line: line,
                                city: repo.getCity(line.cityId),
                                closest: repo.closestStopOnLine(line.id, from!),
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
        ),
      ],
    );
  }
}

class _FavouriteLineCard extends StatelessWidget {
  const _FavouriteLineCard({
    required this.line,
    this.city,
    this.closest,
  });

  final TransitLine line;
  final City? city;
  final ({Stop stop, double meters})? closest;

  @override
  Widget build(BuildContext context) {
    final next = TransitSchedule.nextDepartures(line.frequencyMinutes);
    final subtitleParts = <String>[
      if (city != null) city!.name,
      line.modeLabel,
      'every ${line.frequencyMinutes} min',
      if (closest != null)
        '${closest!.stop.name} · ${TransitSchedule.distanceLabel(closest!.meters)}',
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                LineBadge(line: line),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        subtitleParts.join(' · '),
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                FavoriteStarButton(lineId: line.id),
              ],
            ),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (var i = 0; i < next.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => LineDetailScreen(lineId: line.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        LineBadge(line: line, compact: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            i == 0 ? 'Next departure' : 'Then',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          TransitSchedule.minutesUntilLabel(next[i]),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TransitSchedule.formatTime(next[i]),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LocationSection extends StatefulWidget {
  const _LocationSection({
    required this.location,
    required this.nearby,
  });

  final LocationController location;
  final List<NearbyStop> nearby;

  @override
  State<_LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<_LocationSection> {
  bool _expanded = false;

  LocationController get location => widget.location;
  List<NearbyStop> get nearby => widget.nearby;

  @override
  Widget build(BuildContext context) {
    final searching = location.status == LocationStatus.requesting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Nearby stops (<1km)',
          trailing: IconButton(
            tooltip: 'Refresh nearby stops',
            onPressed: searching ? null : location.requestAccess,
            icon: searching
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: _body(),
        ),
      ],
    );
  }

  Widget _body() {
    if (location.status == LocationStatus.granted && nearby.isNotEmpty) {
      final preview = TransitRepository.nearbyStopLimit;
      final visible = _expanded || nearby.length <= preview
          ? nearby
          : nearby.take(preview).toList();
      final canExpand = nearby.length > preview;

      return Column(
        children: [
          for (final stop in visible) ...[
            _NearbyStopCard(nearby: stop),
            const SizedBox(height: 10),
          ],
          if (canExpand)
            TextButton.icon(
              onPressed: () => setState(() => _expanded = !_expanded),
              icon: Icon(
                _expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
              ),
              label: Text(_expanded ? 'Show less' : 'Show more'),
            ),
        ],
      );
    }

    if (location.status == LocationStatus.granted && nearby.isEmpty) {
      return const _LocationBanner(
        icon: Icons.near_me_disabled_rounded,
        title: 'No stops nearby',
        body: 'Nothing in the sample network is close to you yet.',
      );
    }

    if (location.status == LocationStatus.requesting) {
      return const _LocationBanner(
        icon: Icons.my_location_rounded,
        title: 'Finding nearby stops…',
        body: 'Using your location for the closest stops and next departures.',
      );
    }

    final deniedForever = location.status == LocationStatus.deniedForever;
    final disabled = location.status == LocationStatus.disabled;
    final title = disabled ? 'Turn on location' : 'See nearby stops';
    final body = disabled
        ? 'Location services are off. Turn them on to see nearby stops and next departures.'
        : deniedForever
            ? 'Location is blocked. Enable it in settings to see nearby stops and next departures.'
            : 'Allow location to see the closest stops and the next departures on those lines.';
    final action = disabled || deniedForever ? 'Open settings' : 'Allow location';

    return _LocationBanner(
      icon: Icons.near_me_rounded,
      title: title,
      body: body,
      actionLabel: action,
      onAction: () {
        if (disabled || deniedForever) {
          location.openSettings();
        } else {
          location.requestAccess();
        }
      },
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(icon, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              body,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NearbyStopCard extends StatelessWidget {
  const _NearbyStopCard({required this.nearby});

  final NearbyStop nearby;

  @override
  Widget build(BuildContext context) {
    final next = nearby.departures.take(2).toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.secondarySoft,
                  child: Icon(
                    Icons.hail_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nearby.stop.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        '${TransitSchedule.distanceLabel(nearby.meters)} · ${nearby.stop.lineIds.length} line(s)',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (next.isNotEmpty) ...[
              const SizedBox(height: 12),
              for (final departure in next)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LineDetailScreen(lineId: departure.line.id),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        LineBadge(line: departure.line, compact: true),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            departure.line.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        Text(
                          TransitSchedule.minutesUntilLabel(departure.at),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          TransitSchedule.formatTime(departure.at),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}



