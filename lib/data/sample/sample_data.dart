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
          lineIds: [
          ...lineIdsBySlug[stop.nameSlug] ?? const [],
          if (stop.nameSlug == 'st-hekurudhor') 'pr-train-peje',
        ],
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
    // Trainkos 2026: two daily round trips Prishtinë–Pejë (4201/761 + 760/4200).
    TransitLine(
      id: 'pr-train-peje',
      number: 'T',
      name: 'Prishtinë – Pejë',
      cityId: 'pristina',
      color: AppColors.linePalette[3],
      mode: TransitMode.train,
      destination: 'Pejë',
      frequencyMinutes: 510,
      frequencyLabelOverride: '2 round trips / day',
      dailyDepartureMinutes: const [
        5 * 60 + 32, // 05:32 Pejë → Prishtinë (760)
        7 * 60 + 50, // 07:50 Prishtinë → Pejë (4201)
        12 * 60 + 10, // 12:10 Pejë → Prishtinë (4200)
        16 * 60 + 30, // 16:30 Prishtinë → Pejë (761)
      ],
      stopSlugs: const [
        'rail-prishtine',
        'rail-shkolla-ekonomike',
        'st-hekurudhor',
        'rail-bardh',
        'rail-mjekaj',
        'rail-dritan',
        'rail-drenas',
        'rail-damanek',
        'rail-lugdren',
        'rail-grykas',
        'rail-qarrat',
        'rail-aqareve',
        'rail-ujemir',
        'rail-gurkat',
        'rail-kline',
        'rail-shengjergj',
        'rail-budisalc',
        'rail-arbane',
        'rail-seperant',
        'rail-peje',
      ],
      stops: const [
        LatLng(42.65898, 21.15131),
        LatLng(42.65150, 21.12200),
        LatLng(42.63481, 21.08098),
        LatLng(42.63360, 21.02280),
        LatLng(42.63000, 20.97000),
        LatLng(42.62700, 20.93500),
        LatLng(42.62443, 20.89774),
        LatLng(42.62500, 20.83000),
        LatLng(42.62700, 20.78000),
        LatLng(42.62800, 20.74000),
        LatLng(42.62900, 20.71000),
        LatLng(42.62900, 20.68500),
        LatLng(42.62900, 20.66500),
        LatLng(42.62888, 20.64007),
        LatLng(42.62365, 20.58381),
        LatLng(42.63500, 20.52000),
        LatLng(42.64500, 20.45000),
        LatLng(42.65000, 20.39000),
        LatLng(42.65200, 20.34000),
        LatLng(42.65340, 20.29150),
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
    ..._trainKosPejeStops,
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

  static const _trainKosPejeStops = <Stop>[
    Stop(
      id: 'rail-prishtine',
      name: 'Prishtinë',
      location: LatLng(42.65898, 21.15131),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-shkolla-ekonomike',
      name: 'Shkolla Ekonomike',
      location: LatLng(42.65150, 21.12200),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-bardh',
      name: 'Bardh',
      location: LatLng(42.63360, 21.02280),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-mjekaj',
      name: 'Mjekaj',
      location: LatLng(42.63000, 20.97000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-dritan',
      name: 'Dritan',
      location: LatLng(42.62700, 20.93500),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-drenas',
      name: 'Drenas',
      location: LatLng(42.62443, 20.89774),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-damanek',
      name: 'Damanek',
      location: LatLng(42.62500, 20.83000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-lugdren',
      name: 'Lugdren',
      location: LatLng(42.62700, 20.78000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-grykas',
      name: 'Grykas',
      location: LatLng(42.62800, 20.74000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-qarrat',
      name: 'Qarrat',
      location: LatLng(42.62900, 20.71000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-aqareve',
      name: 'Aqarevë',
      location: LatLng(42.62900, 20.68500),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-ujemir',
      name: 'Ujëmir',
      location: LatLng(42.62900, 20.66500),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-gurkat',
      name: 'Gurkat',
      location: LatLng(42.62888, 20.64007),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-kline',
      name: 'Klinë',
      location: LatLng(42.62365, 20.58381),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-shengjergj',
      name: 'Shëngjergj',
      location: LatLng(42.63500, 20.52000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-budisalc',
      name: 'Budisalc',
      location: LatLng(42.64500, 20.45000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-arbane',
      name: 'Arbanë',
      location: LatLng(42.65000, 20.39000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-seperant',
      name: 'Seperant',
      location: LatLng(42.65200, 20.34000),
      lineIds: ['pr-train-peje'],
    ),
    Stop(
      id: 'rail-peje',
      name: 'Pejë',
      location: LatLng(42.65340, 20.29150),
      lineIds: ['pr-train-peje'],
    ),
  ];
}
