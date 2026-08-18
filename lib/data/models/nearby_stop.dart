import 'stop.dart';
import 'transit_line.dart';

class StopDeparture {
  const StopDeparture({required this.line, required this.at});

  final TransitLine line;
  final DateTime at;
}

class NearbyStop {
  const NearbyStop({
    required this.stop,
    required this.meters,
    required this.departures,
  });

  final Stop stop;
  final double meters;
  final List<StopDeparture> departures;
}
