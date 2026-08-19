import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/stop.dart';
import '../../data/models/transit_line.dart';
import '../../data/repositories/transit_repository.dart';

enum StopTransportKind { bus, intercity, train }

extension StopTransportKindX on StopTransportKind {
  IconData get icon => switch (this) {
        StopTransportKind.bus => Icons.directions_bus_rounded,
        StopTransportKind.intercity => Icons.directions_bus_filled_rounded,
        StopTransportKind.train => Icons.train_rounded,
      };

  Color get color => switch (this) {
        StopTransportKind.bus => AppColors.secondary,
        StopTransportKind.intercity => AppColors.primary,
        StopTransportKind.train => const Color(0xFF7C3AED),
      };

  String get label => switch (this) {
        StopTransportKind.bus => 'Bus',
        StopTransportKind.intercity => 'Intercity bus',
        StopTransportKind.train => 'Train',
      };

  static StopTransportKind fromMode(TransitMode mode) => switch (mode) {
        TransitMode.bus || TransitMode.minibus => StopTransportKind.bus,
        TransitMode.intercity => StopTransportKind.intercity,
        TransitMode.train => StopTransportKind.train,
      };
}

List<StopTransportKind> transportKindsForStop(
  Stop stop, {
  TransitRepository repo = const TransitRepository(),
}) {
  final found = <StopTransportKind>{};
  for (final id in stop.lineIds) {
    final line = repo.getLine(id);
    if (line == null) continue;
    found.add(StopTransportKindX.fromMode(line.mode));
  }
  return [
    for (final kind in StopTransportKind.values)
      if (found.contains(kind)) kind,
  ];
}

class StopModeAvatar extends StatelessWidget {
  const StopModeAvatar({
    super.key,
    required this.kinds,
    this.size = 40,
  });

  final List<StopTransportKind> kinds;
  final double size;

  factory StopModeAvatar.forStop(Stop stop, {Key? key, double size = 40}) {
    return StopModeAvatar(
      key: key,
      kinds: transportKindsForStop(stop),
      size: size,
    );
  }

  @override
  Widget build(BuildContext context) {
    final modes = kinds.isEmpty ? const [StopTransportKind.bus] : kinds;
    return Semantics(
      label: modes.map((kind) => kind.label).join(', '),
      child: SizedBox(
        width: size,
        height: size,
        child: ClipOval(
          child: CustomPaint(
            painter: _StopModePainter(modes),
            child: Stack(
              children: [
                for (var i = 0; i < modes.length; i++)
                  _SliceIcon(
                    index: i,
                    count: modes.length,
                    kind: modes[i],
                    size: size,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliceIcon extends StatelessWidget {
  const _SliceIcon({
    required this.index,
    required this.count,
    required this.kind,
    required this.size,
  });

  final int index;
  final int count;
  final StopTransportKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final iconSize = count == 1 ? size * 0.5 : size * (count == 2 ? 0.38 : 0.3);
    if (count == 1) {
      return Center(
        child: Icon(
          kind.icon,
          key: Key('stop-mode-${kind.name}'),
          color: kind.color,
          size: iconSize,
        ),
      );
    }

    final start = -math.pi / 2 + index * (2 * math.pi / count);
    final mid = start + math.pi / count;
    final radius = size * 0.28;

    return Align(
      alignment: Alignment(
        math.cos(mid) * (radius * 2 / size),
        math.sin(mid) * (radius * 2 / size),
      ),
      child: Icon(
        kind.icon,
        key: Key('stop-mode-${kind.name}'),
        color: kind.color,
        size: iconSize,
      ),
    );
  }
}

class _StopModePainter extends CustomPainter {
  const _StopModePainter(this.kinds);

  final List<StopTransportKind> kinds;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / kinds.length;

    for (var i = 0; i < kinds.length; i++) {
      final start = -math.pi / 2 + i * sweep;
      final paint = Paint()
        ..color = kinds[i].color.withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      if (kinds.length == 1) {
        canvas.drawCircle(center, radius, paint);
      } else {
        canvas.drawArc(rect, start, sweep, true, paint);
      }
    }

    if (kinds.length > 1) {
      final divider = Paint()
        ..color = Colors.white
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      for (var i = 0; i < kinds.length; i++) {
        final angle = -math.pi / 2 + i * sweep;
        canvas.drawLine(
          center,
          Offset(
            center.dx + math.cos(angle) * radius,
            center.dy + math.sin(angle) * radius,
          ),
          divider,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StopModePainter oldDelegate) {
    return oldDelegate.kinds != kinds;
  }
}
