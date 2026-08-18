/// Headway-based sample timetable (05:00–23:00) until real GTFS lands.
abstract final class TransitSchedule {
  static const serviceStartHour = 5;
  static const serviceEndHour = 23;

  static DateTime nextDeparture(int frequencyMinutes, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final freq = frequencyMinutes <= 0 ? 15 : frequencyMinutes;
    var start = DateTime(
      current.year,
      current.month,
      current.day,
      serviceStartHour,
    );
    final end = DateTime(
      current.year,
      current.month,
      current.day,
      serviceEndHour,
    );

    if (current.isAfter(end) || current.isAtSameMomentAs(end)) {
      start = start.add(const Duration(days: 1));
      return start;
    }

    var next = start;
    while (next.isBefore(current)) {
      next = next.add(Duration(minutes: freq));
    }
    if (next.isAfter(end)) {
      return DateTime(
        current.year,
        current.month,
        current.day,
        serviceStartHour,
      ).add(const Duration(days: 1));
    }
    return next;
  }

  static String formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String minutesUntilLabel(DateTime at, [DateTime? now]) {
    final current = now ?? DateTime.now();
    final minutes = at.difference(current).inMinutes;
    if (minutes <= 0) return 'now';
    if (minutes == 1) return '1 min';
    return '$minutes min';
  }

  static String distanceLabel(double meters) {
    if (meters < 1000) {
      return '${meters.round()} m';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
}
