import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/stop.dart';
import '../../data/repositories/transit_repository.dart';
import '../../data/schedule.dart';
import '../widgets/favorite_star_button.dart';
import '../widgets/line_badge.dart';
import '../widgets/stop_mode_avatar.dart';

class StopCard extends StatelessWidget {
  const StopCard({
    super.key,
    required this.stop,
    this.meters,
    this.onTap,
  });

  final Stop stop;
  final double? meters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const repo = TransitRepository();
    final lines = [
      for (final id in stop.lineIds) ?repo.getLine(id),
    ];
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: StopModeAvatar.forStop(stop),
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
