import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';
import '../models/city.dart';
import '../models/stop.dart';
import '../models/transit_line.dart';

/// Placeholder network so UI can be built before real GTFS / operator feeds.
abstract final class SampleData {
  static const cities = <City>[
    City(
      id: 'pristina',
      name: 'Pristina',
      nameLocal: 'Prishtinë',
      country: Country.kosovo,
      center: LatLng(42.6629, 21.1655),
      lineCount: 4,
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

  static final lines = <TransitLine>[
    // Pristina
    TransitLine(
      id: 'pr-1',
      number: '1',
      name: 'Qendra – Kalabri',
      cityId: 'pristina',
      color: AppColors.linePalette[0],
      mode: TransitMode.bus,
      destination: 'Kalabri',
      frequencyMinutes: 12,
      stops: const [
        LatLng(42.6629, 21.1655),
        LatLng(42.6580, 21.1580),
        LatLng(42.6520, 21.1500),
        LatLng(42.6450, 21.1400),
      ],
    ),
    TransitLine(
      id: 'pr-4',
      number: '4',
      name: 'Qendra – Sunny Hill',
      cityId: 'pristina',
      color: AppColors.linePalette[1],
      mode: TransitMode.bus,
      destination: 'Sunny Hill',
      frequencyMinutes: 15,
      stops: const [
        LatLng(42.6629, 21.1655),
        LatLng(42.6680, 21.1720),
        LatLng(42.6750, 21.1800),
      ],
    ),
    TransitLine(
      id: 'pr-7',
      number: '7',
      name: 'Terminal – Germia',
      cityId: 'pristina',
      color: AppColors.linePalette[2],
      mode: TransitMode.bus,
      destination: 'Germia',
      frequencyMinutes: 18,
      stops: const [
        LatLng(42.6550, 21.1550),
        LatLng(42.6629, 21.1655),
        LatLng(42.6700, 21.1850),
        LatLng(42.6780, 21.2000),
      ],
    ),
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
    const Stop(
      id: 'pr-qendra',
      name: 'Sheshi Skënderbeu',
      location: LatLng(42.6629, 21.1655),
      lineIds: ['pr-1', 'pr-4', 'pr-7'],
    ),
    const Stop(
      id: 'pr-terminal',
      name: 'Terminali i Autobusëve',
      location: LatLng(42.6550, 21.1550),
      lineIds: ['pr-7', 'pr-ic-prizren'],
    ),
    const Stop(
      id: 'pr-kalabri',
      name: 'Kalabri',
      location: LatLng(42.6450, 21.1400),
      lineIds: ['pr-1'],
    ),
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
