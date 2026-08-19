# Soar Albania — Version 0.1.3

**Release date:** 19 August 2026  
**Branch:** `main`

---

## Highlights

### Settings
- Settings is now a grouped list: **My account**, **App Settings**, **Support**, and **About**
- **Third-party licenses** shows only notices that need attribution (OpenStreetMap and Plus Jakarta Sans), not every package
- Footer has **Log in** (not available yet) and `Copyright Soar Albania @ 2026 v` plus the installed app version

### Saved places
- **Home** and **Work** are always there as slots; you can also add custom places
- Set a place with a name, address text, current location, or a nearby stop
- Manage them from **Edit favourites → Places**, or from Settings → Manage my favourites

### Favourites editor
- Full-screen editor is split into **Lines**, **Stops**, and **Places** tabs
- Default tab is **Lines**
- Edit on the Lines page opens Lines; edit on the Stops page opens Stops

### Transit
- Saved places sit in a **horizontal row**: Home/Work as icons, custom places as titles
- Empty Home/Work slots stay hidden
- If nothing is saved, the sheet says **No addresses saved yet** with an **Add a place** button that opens the Places tab
- Tap a saved place to **plan a route** from your location (walk + a one-seat ride when a line connects)
- Bottom sheet is **draggable** up to full screen
- The scrollable panel lists **favourite stops** and **nearby stops** the same way as the Stops tab
- Tap a stop: sheet drops to **half height**, map centers the stop in the **visible top half**
- **My location** sits 50px above the blue sheet and 50px from the right

### Stop icons
- Bus, intercity bus, and train stops have their own icons
- Shared stops split the circle in **halves** or **thirds**

### Trainkos
- Real **Prishtinë – Pejë** passenger train: **2 round trips / day**
- Official 2026 times: 05:32 and 12:10 from Pejë; 07:50 and 16:30 from Prishtinë
- Stops from Prishtinë through Fushë Kosovë, Drenas, Klinë to Pejë
- **St. Hekurudhor** is both a bus stop and the Fushë Kosovë train halt

---

## Technical notes

- Version **0.1.3+3**
- **`package_info_plus`** for the Settings copyright version
- **`SavedAddress`**: Home/Work presets, `isSet` / `hasCoordinates`, `displayAddresses` on **`FavoritesController`**
- **`SaveAddressScreen`** + **`ThirdPartyLicensesScreen`**
- **`FavouritesTab`** on **`EditFavouritesScreen`**
- **`TripPlan`** / **`TransitRepository.planTrip`** — closest stops, shared-line ride, walk fallback
- **`TransitLine.dailyDepartureMinutes`** and **`frequencyLabel`** for fixed daily trips
- **`StopModeAvatar`** — bus / intercity / train, split painter
- **`FavouriteStopsSection`**, **`NearbyStopsSection`**, **`StopCard`** shared by Stops and Transit
- Transit sheet is a **`DraggableScrollableSheet`** (`min` / `0.5` / `1.0`); location button is `Positioned`

---

## Google Play Console — paste as-is (plain text)

Play Store release notes do not support Markdown. Limit is **500 characters** per language. Copy everything inside the code block below into **What's new in this release?**.

```
<en-US>
What's new in 0.1.3

• Settings list: account, app, support, about
• Save Home, Work, and custom places
• Transit: drag the sheet, tap a place for a route
• Favourite and nearby stops on Transit
• Bus, intercity, and train stop icons
• Prishtinë–Pejë train, two round trips a day
</en-US>
```
