/// Headway-based sample timetable (05:00–23:00) until real GTFS lands.
abstract final class TransitSchedule {
  static const serviceStartHour = 5;
  static const serviceEndHour = 23;

  static DateTime nextDeparture(
    int frequencyMinutes, [
    DateTime? now,
    List<int>? dailyMinutes,
  ]) {
    if (dailyMinutes != null && dailyMinutes.isNotEmpty) {
      return nextDailyDeparture(dailyMinutes, now);
    }

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

  static List<DateTime> nextDepartures(
    int frequencyMinutes, {
    int count = 2,
    DateTime? now,
    List<int>? dailyMinutes,
  }) {
    final result = <DateTime>[];
    var cursor = now ?? DateTime.now();
    for (var i = 0; i < count; i++) {
      final next = nextDeparture(frequencyMinutes, cursor, dailyMinutes);
      result.add(next);
      cursor = next.add(const Duration(milliseconds: 1));
    }
    return result;
  }

  static DateTime nextDailyDeparture(
    List<int> minutesFromMidnight, [
    DateTime? now,
  ]) {
    final current = now ?? DateTime.now();
    final sorted = [...minutesFromMidnight]..sort();
    final startOfDay = DateTime(current.year, current.month, current.day);
    for (final minutes in sorted) {
      final at = startOfDay.add(Duration(minutes: minutes));
      if (!at.isBefore(current)) return at;
    }
    return startOfDay.add(Duration(days: 1, minutes: sorted.first));
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
