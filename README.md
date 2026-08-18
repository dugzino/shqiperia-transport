# Kosova Transit

Mobile app for public transportation across **Kosovo** and **Albania**.

Built with Flutter (Android + iOS). Web will live in a separate codebase later.

## Features (scaffold)

- **Home** — pick a city, browse local lines
- **Map** — OpenStreetMap routes and stops (`flutter_map`)
- **Lines** — filter by country / intercity
- **Search** — cities, lines, and stops
- **Sample data** — placeholder network until GTFS / operator APIs land

## Run

```bash
flutter pub get
flutter run
```

## Project layout

```
lib/
  app.dart                 # MaterialApp + themes
  main.dart
  core/theme/              # Colors & ThemeData
  data/
    models/                # City, TransitLine, Stop
    repositories/          # TransitRepository (sample → real feeds later)
    sample/                # Placeholder network
  features/
    shell/                 # Bottom navigation
    home/ map/ lines/ search/
```

## Next steps

1. Real schedule data (GTFS or operator feeds)
2. Live vehicle positions (where available)
3. Favorites & trip planning
4. Offline caching
```
