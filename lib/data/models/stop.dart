import 'package:latlong2/latlong.dart';

class Stop {
  const Stop({
    required this.id,
    required this.name,
    required this.location,
    this.lineIds = const [],
  });

  final String id;
  final String name;
  final LatLng location;
  final List<String> lineIds;
}
