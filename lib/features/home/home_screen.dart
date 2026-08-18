import 'package:flutter/material.dart';

import '../../core/location/location_controller.dart';
import '../../core/location/location_scope.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/city.dart';
import '../../data/models/nearby_stop.dart';
import '../../data/repositories/transit_repository.dart';
import '../../data/schedule.dart';
import '../widgets/line_badge.dart';
import '../widgets/section_header.dart';
import '../lines/line_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _repo = TransitRepository();
  late City _selectedCity;
  bool _userPickedCity = false;
  String? _appliedCityFromLocation;

  @override
  void initState() {
    super.initState();
    _selectedCity = _repo.getCities().first;
  }

  void _applyNearestCity(LocationController location) {
    final pos = location.position;
    if (_userPickedCity || pos == null) return;
    final nearest = _repo.nearestCity(pos);
    if (_appliedCityFromLocation == nearest.id) return;
    _appliedCityFromLocation = nearest.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _userPickedCity) return;
      if (_selectedCity.id != nearest.id) {
        setState(() => _selectedCity = nearest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = LocationScope.maybeOf(context);
    if (location != null) _applyNearestCity(location);
    final nearby = location?.position == null
        ? const <NearbyStop>[]
        : _repo.nearbyStops(location!.position!);
    final lines = _repo.getLines(cityId: _selectedCity.id);
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soar Albania',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Buses & routes across Kosovo and Albania',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: _HeroCard(city: _selectedCity, lineCount: lines.length),
              ),
            ),
            if (location != null)
              SliverToBoxAdapter(
                child: _LocationSection(
                  location: location,
                  nearby: nearby,
                ),
              ),
            const SliverToBoxAdapter(
              child: SectionHeader(title: 'Cities'),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 108,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  itemCount: _repo.getCities().length,
                  separatorBuilder: (_, _) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final city = _repo.getCities()[index];
                    final selected = city.id == _selectedCity.id;
                    return _CityChip(
                      city: city,
                      selected: selected,
                      onTap: () => setState(() {
                        _userPickedCity = true;
                        _selectedCity = city;
                      }),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionHeader(
                title: 'Lines in ${_selectedCity.name}',
              ),
            ),
            if (lines.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'No lines yet for this city.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList.separated(
                  itemCount: lines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final line = lines[index];
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
                          '${line.modeLabel} · every ${line.frequencyMinutes} min',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
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
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.city, required this.lineCount});

  final City city;
  final int lineCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryLight],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.28),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(city.flag, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text(
                city.countryLabel,
                style: const TextStyle(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            city.nameLocal,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            city.name == city.nameLocal ? city.countryLabel : city.name,
            style: const TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _StatPill(icon: Icons.route_rounded, label: '$lineCount lines'),
              const _StatPill(
                icon: Icons.schedule_rounded,
                label: 'Sample data',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationSection extends StatelessWidget {
  const _LocationSection({
    required this.location,
    required this.nearby,
  });

  final LocationController location;
  final List<NearbyStop> nearby;

  @override
  Widget build(BuildContext context) {
    if (location.status == LocationStatus.granted && nearby.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Nearby stops'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Column(
              children: [
                for (final stop in nearby) ...[
                  _NearbyStopCard(nearby: stop),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      );
    }

    if (location.status == LocationStatus.granted && nearby.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: _LocationBanner(
          icon: Icons.near_me_disabled_rounded,
          title: 'No stops nearby',
          body: 'Nothing in the sample network is close to you yet. Browse cities below.',
        ),
      );
    }

    if (location.status == LocationStatus.requesting) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: _LocationBanner(
          icon: Icons.my_location_rounded,
          title: 'Finding nearby stops…',
          body: 'Using your location for the closest stops and next departures.',
        ),
      );
    }

    final deniedForever = location.status == LocationStatus.deniedForever;
    final disabled = location.status == LocationStatus.disabled;
    final title = disabled
        ? 'Turn on location'
        : 'See nearby stops';
    final body = disabled
        ? 'Location services are off. Turn them on to see nearby stops and next departures.'
        : deniedForever
            ? 'Location is blocked. Enable it in settings to see nearby stops and next departures.'
            : 'Allow location to see the closest stops and the next departures on those lines.';
    final action = disabled || deniedForever ? 'Open settings' : 'Allow location';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: _LocationBanner(
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
      ),
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

class _CityChip extends StatelessWidget {
  const _CityChip({
    required this.city,
    required this.selected,
    required this.onTap,
  });

  final City city;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 132,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(city.flag, style: const TextStyle(fontSize: 18)),
              const Spacer(),
              Text(
                city.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                city.countryLabel,
                style: TextStyle(
                  fontSize: 12,
                  color: selected ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

