import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../models/city.dart';
import '../models/stop.dart';
import '../models/transit_line.dart';
import 'prishtina_network.dart';

/// Placeholder network so UI can be built before real GTFS / operator feeds.
abstract final class SampleData {
  static const cities = <City>[
    City(
      id: 'pristina',
      name: 'Pristina',
      nameLocal: 'Prishtinë',
      country: Country.kosovo,
      center: LatLng(42.6629, 21.1655),
      lineCount: 21,
    ),
    City(
      id: 'prizren',
      name: 'Prizren',
      nameLocal: 'Prizren',
      country: Country.kosovo,
      center: LatLng(42.2139, 20.7397),
      lineCount: 2,
    ),
    City(
      id: 'peja',
      name: 'Peja',
      nameLocal: 'Pejë',
      country: Country.kosovo,
      center: LatLng(42.6593, 20.2883),
      lineCount: 1,
    ),
    City(
      id: 'tirana',
      name: 'Tirana',
      nameLocal: 'Tiranë',
      country: Country.albania,
      center: LatLng(41.3275, 19.8187),
      lineCount: 3,
    ),
    City(
      id: 'durres',
      name: 'Durrës',
      nameLocal: 'Durrës',
      country: Country.albania,
      center: LatLng(41.3231, 19.4414),
      lineCount: 1,
    ),
    City(
      id: 'shkoder',
      name: 'Shkodër',
      nameLocal: 'Shkodër',
      country: Country.albania,
      center: LatLng(42.0683, 19.5126),
      lineCount: 1,
    ),
  ];

  static final _prishtinaUrbanLines = _buildPrishtinaLines();

  static List<TransitLine> _buildPrishtinaLines() {
    final bySlug = {
      for (final stop in prishtinaBusStops) stop.nameSlug: stop,
    };
    return [
      for (var i = 0; i < prishtinaLines.length; i++)
        TransitLine(
          id: 'pr-${(prishtinaLines[i].number ?? '${i + 1}').toLowerCase()}',
          number: prishtinaLines[i].number ?? '${i + 1}',
          name: prishtinaLines[i].name,
          cityId: 'pristina',
          color: AppColors.linePalette[i % AppColors.linePalette.length],
          mode: TransitMode.bus,
          destination: prishtinaLines[i].stops.isEmpty
              ? null
              : bySlug[prishtinaLines[i].stops.last.nameSlug]?.name,
          frequencyMinutes: 15,
          stopSlugs: [
            for (final stop in prishtinaLines[i].stops) stop.nameSlug,
          ],
          stops: [
            for (final stop in prishtinaLines[i].stops)
              if (bySlug[stop.nameSlug] case final raw?)
                LatLng(raw.lat, raw.lng),
          ],
        ),
    ];
  }

  static List<Stop> _buildPrishtinaStops() {
    final lineIdsBySlug = <String, List<String>>{};
    for (final line in _prishtinaUrbanLines) {
      for (final slug in line.stopSlugs) {
        lineIdsBySlug.putIfAbsent(slug, () => []).add(line.id);
      }
    }
    return [
      for (final stop in prishtinaBusStops)
        Stop(
          id: stop.nameSlug,
          name: stop.name,
          location: LatLng(stop.lat, stop.lng),
          lineIds: lineIdsBySlug[stop.nameSlug] ?? const [],
        ),
    ];
  }

  static final lines = <TransitLine>[
    ..._prishtinaUrbanLines,
    TransitLine(
      id: 'pr-ic-prizren',
      number: 'IC',
      name: 'Pristina – Prizren',
      cityId: 'pristina',
      color: AppColors.linePalette[4],
      mode: TransitMode.intercity,
      destination: 'Prizren',
      frequencyMinutes: 60,
      stops: const [
        LatLng(42.6629, 21.1655),
        LatLng(42.3800, 20.9000),
        LatLng(42.2139, 20.7397),
      ],
    ),
    // Prizren
    TransitLine(
      id: 'pz-1',
      number: '1',
      name: 'Qendra – Arbana',
      cityId: 'prizren',
      color: AppColors.linePalette[3],
      mode: TransitMode.bus,
      destination: 'Arbana',
      frequencyMinutes: 20,
      stops: const [
        LatLng(42.2139, 20.7397),
        LatLng(42.2100, 20.7300),
        LatLng(42.2050, 20.7200),
      ],
    ),
    TransitLine(
      id: 'pz-2',
      number: '2',
      name: 'Terminal – Shatërvani',
      cityId: 'prizren',
      color: AppColors.linePalette[5],
      mode: TransitMode.minibus,
      destination: 'Shatërvani',
      frequencyMinutes: 15,
      stops: const [
        LatLng(42.2200, 20.7500),
        LatLng(42.2139, 20.7397),
        LatLng(42.2090, 20.7350),
      ],
    ),
    // Peja
    TransitLine(
      id: 'pe-1',
      number: '1',
      name: 'Qendra – Rugova',
      cityId: 'peja',
      color: AppColors.linePalette[6],
      mode: TransitMode.bus,
      destination: 'Rugova',
      frequencyMinutes: 25,
      stops: const [
        LatLng(42.6593, 20.2883),
        LatLng(42.6650, 20.2800),
        LatLng(42.6750, 20.2700),
      ],
    ),
    // Tirana
    TransitLine(
      id: 'tr-l1',
      number: 'L1',
      name: 'Kombinat – Kinostudio',
      cityId: 'tirana',
      color: AppColors.linePalette[0],
      mode: TransitMode.bus,
      destination: 'Kinostudio',
      frequencyMinutes: 10,
      stops: const [
        LatLng(41.3100, 19.7800),
        LatLng(41.3200, 19.8000),
        LatLng(41.3275, 19.8187),
        LatLng(41.3400, 19.8400),
      ],
    ),
    TransitLine(
      id: 'tr-l2',
      number: 'L2',
      name: 'Unaza e Vogël',
      cityId: 'tirana',
      color: AppColors.linePalette[1],
      mode: TransitMode.bus,
      destination: 'Unaza',
      frequencyMinutes: 8,
      stops: const [
        LatLng(41.3275, 19.8187),
        LatLng(41.3300, 19.8300),
        LatLng(41.3250, 19.8400),
        LatLng(41.3200, 19.8250),
        LatLng(41.3275, 19.8187),
      ],
    ),
    TransitLine(
      id: 'tr-ic-durres',
      number: 'IC',
      name: 'Tirana – Durrës',
      cityId: 'tirana',
      color: AppColors.linePalette[7],
      mode: TransitMode.intercity,
      destination: 'Durrës',
      frequencyMinutes: 30,
      stops: const [
        LatLng(41.3275, 19.8187),
        LatLng(41.3250, 19.6500),
        LatLng(41.3231, 19.4414),
      ],
    ),
    // Durrës
    TransitLine(
      id: 'du-1',
      number: '1',
      name: 'Port – Plazh',
      cityId: 'durres',
      color: AppColors.linePalette[5],
      mode: TransitMode.bus,
      destination: 'Plazh',
      frequencyMinutes: 15,
      stops: const [
        LatLng(41.3100, 19.4500),
        LatLng(41.3231, 19.4414),
        LatLng(41.3350, 19.4300),
      ],
    ),
    // Shkodër
    TransitLine(
      id: 'sh-1',
      number: '1',
      name: 'Qendra – Rozafa',
      cityId: 'shkoder',
      color: AppColors.linePalette[2],
      mode: TransitMode.minibus,
      destination: 'Rozafa',
      frequencyMinutes: 20,
      stops: const [
        LatLng(42.0683, 19.5126),
        LatLng(42.0600, 19.5000),
        LatLng(42.0460, 19.4930),
      ],
    ),
  ];

  static final stops = <Stop>[
    ..._buildPrishtinaStops(),
    const Stop(
      id: 'tr-skanderbeg',
      name: 'Sheshi Skënderbej',
      location: LatLng(41.3275, 19.8187),
      lineIds: ['tr-l1', 'tr-l2', 'tr-ic-durres'],
    ),
    const Stop(
      id: 'tr-kinostudio',
      name: 'Kinostudio',
      location: LatLng(41.3400, 19.8400),
      lineIds: ['tr-l1'],
    ),
    const Stop(
      id: 'pz-shatervan',
      name: 'Shatërvani',
      location: LatLng(42.2090, 20.7350),
      lineIds: ['pz-2'],
    ),
    const Stop(
      id: 'pe-qendra',
      name: 'Pejë Qendra',
      location: LatLng(42.6593, 20.2883),
      lineIds: ['pe-1'],
    ),
    const Stop(
      id: 'du-port',
      name: 'Porti i Durrësit',
      location: LatLng(41.3100, 19.4500),
      lineIds: ['du-1', 'tr-ic-durres'],
    ),
    const Stop(
      id: 'sh-qendra',
      name: 'Shkodër Qendra',
      location: LatLng(42.0683, 19.5126),
      lineIds: ['sh-1'],
    ),
  ];
}
