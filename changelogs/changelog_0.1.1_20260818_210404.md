# Soar Albania — Version 0.1.1

**Release date:** 18 August 2026  
**Branch:** `main`

---

## Highlights

### Brand
- App is now **Soar Albania** (was Kosova Transit / Shqiperia Transport)
- Home title, Android launcher name, iOS display name, and Play listing all use the new name

### Icon & splash
- Simple **front-facing bus** on transit blue — reads as a transport app
- Blue **fills the whole Android circle** (adaptive icon), same idea as Calendar / Chrome
- **Boot splash** is the same blue screen and bus

### Location
- Asks for **location** so the app can show **nearby stops** and the **next departure**
- Home lists the closest stops with walking distance and minutes until the next bus
- Nearest city is selected automatically (you can still pick another)
- Map: **My location** button and a user marker

### Play Store
- High-res icon, feature graphic, and phone / tablet screenshots in `store/play/`
- Listing copy uses **Kosova** and **Prishtina**

---

## Technical notes

- Flutter package **`soar_albania`**; Android `com.dugzino.soar_albania`; iOS `com.dugzino.soarAlbania`
- **`SoarAlbaniaApp`** is the root widget
- **`LocationController`** / **`LocationScope`** — `geolocator`; request on first frame; denied / forever / services-off banners
- **`TransitRepository.nearbyStops`** / **`nearestCity`**; **`TransitSchedule`** headway timetable (05:00–23:00) until GTFS
- Adaptive icon: `@color/ic_launcher_background` `#0B3D91` + `ic_launcher_foreground` bus; `launch_background` splash
- Play assets rebuilt from `tool/build_transport_icon.py` and `tool/build_play_assets.py`

---

## Google Play Console — paste as-is (plain text)

Play Store release notes do not support Markdown. Limit is **500 characters** per language. Copy everything inside the code block below into **What's new in this release?**.

```
<en-US>
What's new in 0.1.1

• Soar Albania — buses and routes across Kosova and Albania
• New bus icon; fills the Android launcher circle
• Same icon on the boot screen
• Allow location for nearby stops and the next departure
• Map shows your position
</en-US>
```
