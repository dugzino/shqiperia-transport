import 'package:latlong2/latlong.dart';

enum Country { kosovo, albania }

class City {
  const City({
    required this.id,
    required this.name,
    required this.nameLocal,
    required this.country,
    required this.center,
    this.lineCount = 0,
  });

  final String id;
  final String name;
  final String nameLocal;
  final Country country;
  final LatLng center;
  final int lineCount;

  String get countryLabel => switch (country) {
    Country.kosovo => 'Kosovo',
    Country.albania => 'Albania',
  };

  String get flag => switch (country) {
    Country.kosovo => '🇽🇰',
    Country.albania => '🇦🇱',
  };
}
