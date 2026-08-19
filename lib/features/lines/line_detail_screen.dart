import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../core/theme/app_colors.dart';
import '../../data/repositories/transit_repository.dart';
import '../widgets/favorite_star_button.dart';
import '../widgets/line_badge.dart';

class LineDetailScreen extends StatelessWidget {
  const LineDetailScreen({super.key, required this.lineId});

  final String lineId;

  @override
  Widget build(BuildContext context) {
    const repo = TransitRepository();
    final line = repo.getLine(lineId);

    if (line == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Line')),
        body: const Center(child: Text('Line not found.')),
      );
    }

    final city = repo.getCity(line.cityId);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Line ${line.number}'),
        actions: [
          FavoriteStarButton(lineId: line.id),
        ],
      ),
      body: ListView(
        children: [
          if (line.stops.length >= 2)
            SizedBox(
              height: 220,
              child: FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(line.stops),
                    padding: const EdgeInsets.all(36),
                  ),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                  ),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dugzino.shqiperia_transport',
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: line.stops,
                        color: line.color,
                        strokeWidth: 5,
                      ),
                    ],
                  ),
                  MarkerLayer(
                    markers: [
                      for (var i = 0; i < line.stops.length; i++)
                        Marker(
                          point: line.stops[i],
                          width: 14,
                          height: 14,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: i == 0 || i == line.stops.length - 1
                                  ? line.color
                                  : Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: line.color, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    LineBadge(line: line),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            line.name,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (city != null)
                            Text(
                              '${city.nameLocal} · ${city.countryLabel}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _InfoChip(
                      icon: line.modeIcon,
                      label: line.modeLabel,
                    ),
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: 'Every ${line.frequencyMinutes} min',
                    ),
                    if (line.destination != null)
                      _InfoChip(
                        icon: Icons.flag_rounded,
                        label: line.destination!,
                      ),
                  ],
                ),
                const SizedBox(height: 28),
                Text(
                  'Stops',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...List.generate(line.stops.length, (index) {
                  final isFirst = index == 0;
                  final isLast = index == line.stops.length - 1;
                  final named = index < line.stopSlugs.length
                      ? repo.getStop(line.stopSlugs[index])?.name
                      : null;
                  final label = named ??
                      (isFirst
                          ? 'Start · stop ${index + 1}'
                          : isLast
                              ? 'End · stop ${index + 1}'
                              : 'Stop ${index + 1}');
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Column(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: isFirst || isLast
                                      ? line.color
                                      : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: line.color,
                                    width: 2.5,
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Expanded(
                                  child: Container(
                                    width: 2.5,
                                    color: line.color.withValues(alpha: 0.35),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              bottom: isLast ? 0 : 18,
                              left: 4,
                            ),
                            child: Text(
                              label,
                              style: TextStyle(
                                fontWeight: isFirst || isLast
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                height: 1.1,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.secondarySoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.secondary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Schedules are sample data. Live GTFS and operator feeds will replace this later.',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary,
                          ),
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

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
