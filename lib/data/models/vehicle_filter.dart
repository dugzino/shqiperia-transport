import 'transit_line.dart';

enum VehicleFilter { bus, intercity, train, all }

extension VehicleFilterX on VehicleFilter {
  String get label => switch (this) {
        VehicleFilter.bus => 'Bus',
        VehicleFilter.intercity => 'Intercity Bus',
        VehicleFilter.train => 'Train',
        VehicleFilter.all => 'All',
      };

  bool matchesLine(TransitLine line) => switch (this) {
        VehicleFilter.all => true,
        VehicleFilter.bus =>
          line.mode == TransitMode.bus || line.mode == TransitMode.minibus,
        VehicleFilter.intercity => line.mode == TransitMode.intercity,
        VehicleFilter.train => line.mode == TransitMode.train,
      };
}
