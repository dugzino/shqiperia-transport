# Soar Albania — Version 0.1.2

**Release date:** 19 August 2026  
**Branch:** `main`

---

## Highlights

### Navigation
- Bottom bar is now **Transit · Lines · Stops · Tickets · Settings**
- App opens on **Lines**
- **Tickets** is greyed out; tap it and you get “Tickets are not available yet.”
- Home and Search are no longer in the bar

### Transit
- Map-only tab with a **Where to?** search bar
- Blue grab sheet at the bottom for **saved addresses**
- Pull the sheet to see **favourite stops** on a light grey list
- My-location button still jumps the map to you

### Lines & Stops
- Each page has **favourites** (edit button) and **nearby (&lt;1 km)** (refresh)
- Nearby lists show **3** items, then **Show more**
- Nearby is filtered by **Bus** (default), **Intercity Bus**, **Train**, or **All**
- Favourites stay unfiltered at the top

### Favourites
- Star a line or stop to pin it
- Full-screen editor to add or remove favourite lines and stops
- Pins persist across launches

### Prishtina network
- Hand-editable stop and line arrays (`lib/data/sample/prishtina_network.dart`)
- Seeded from OpenStreetMap named stops and Trafiku Urban routes — sequences can be corrected by hand

### Look & copy
- Status bar and page titles use the **launcher blue** (`#0B3D91`)
- Country **flag emojis removed**; user-facing **Kosovo** is **Kosova**

---

## Technical notes

- Version **0.1.2+2**
- **`FavoritesController`** / **`FavoritesScope`** — `shared_preferences` for line ids, stop ids, and saved addresses
- **`prishtinaBusStops`** / **`prishtinaLines`** — `{lat, lng, name, nameSlug}` and `{name, stops: [{stopNumber, nameSlug}]}`
- **`TransitRepository.nearbyLines`**, **`nearbyStopsMatching`**, **`favouriteLinesMatching`**, **`favouriteStopsMatching`**
- Nearby radius remains **500 m** (1 km diameter); favourite-line ranking on Home is still **3 closest within 10 km**
- **`VehicleFilter`**: bus (includes minibus), intercity, train, all
- **`EditFavouritesScreen`** is a fullscreen dialog; Transit sheet key `transit-sheet-handle`
- Status bar: `AppTheme.statusBar` + Android `statusBarColor` `#0B3D91` + iOS `UIStatusBarStyleLightContent`

---

## Google Play Console — paste as-is (plain text)

Play Store release notes do not support Markdown. Limit is **500 characters** per language. Copy everything inside the code block below into **What's new in this release?**.

```
<en-US>
What's new in 0.1.2

• New tabs: Transit, Lines, Stops, Settings
• Transit: map, Where to?, and a sheet for saved places
• Lines and Stops: favourites plus nearby (under 1 km)
• Star lines and stops; they stay pinned
• More Prishtina stops and routes
• Kosova spelling; no country flags
</en-US>
```
