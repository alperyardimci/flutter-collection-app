# Banknote Collections (Flutter)

A Flutter app for tracking world banknotes by country and continent. Features a modern, grouped countries UI, quick add/edit banknote flow with image support, and simple local persistence.

---

## Highlights
- Countries grouped by continent with compact flag tiles.
- Flags are colorful when a country has at least one saved photo; monochrome otherwise.
- Numeric image badge on each country's flag.
- Add banknote UI with photo (camera/gallery), denomination, notes, and circulation years (start/end with `Present` option).
- Country dataset loaded from `assets/countries.json`.
- Local persistence via Hive (see `lib/data/banknote_entry.dart` and `lib/data/banknote_store.dart`).

## Repo layout (important files)
- `lib/main.dart` — app bootstrap.
- `lib/screens/world_map_screen.dart` — main screen: grouped countries UI.
- `lib/screens/add_banknote_screen.dart` — add/edit screen with image controls and year pickers.
- `lib/screens/country_detail_screen.dart` — country detail list (banknotes per country).
- `lib/data/country_data.dart` — loads `assets/countries.json` into `Countries.all`.
- `assets/countries.json` — canonical country list used in the UI.
- `lib/data/banknote_entry.dart` — banknote model (includes `circulationStart` / `circulationEnd`).
- `lib/data/banknote_store.dart` — persistence helpers (Hive wrappers).
- `pubspec.yaml` — Flutter package and asset declarations.

## Quick start (Windows PowerShell)

Make sure you have Flutter installed and a device/emulator or web target available.

1. Open PowerShell and change into the repo:

```powershell
cd C:\Users\yardi\Collections\banknote_collections
```

2. Get packages:

```powershell
flutter pub get
```

3. Run analyzer (recommended):

```powershell
flutter analyze
```

4. Run the app on a device (examples):

- Android emulator (if running):

```powershell
flutter devices
flutter run -d emulator-5554
```

- Web (Chrome):

```powershell
flutter run -d chrome
```

- Windows desktop:

```powershell
flutter run -d windows
```

Note: Windows desktop requires Visual Studio toolchain (C++ workload) installed and configured for Flutter. If you see "Unable to find suitable Visual Studio toolchain", run `flutter doctor` and follow its instructions.

## Development notes & decisions
- Country list: `assets/countries.json` is the source of truth. `Countries.loadFromAsset()` loads it at startup in `lib/main.dart`.
- Flags: currently using Unicode emoji regional indicators for flags. If you prefer pixel-perfect flags, replace with PNG/SVG assets (and update `world_map_screen.dart` to use `Image.asset`).
- Monochrome effect: emoji flags are desaturated using a `ColorFiltered` matrix when a country has zero saved images.
- Image counts: currently computed synchronously (scans `BanknoteStore.getByCountry()` and `File.existsSync`). For very large collections this can cause startup jank — converting to an asynchronous cached approach is recommended.
- Add Banknote: circulation start/end saved as strings (year or 'Present') and stored in `BanknoteEntry`.

## UI & behavior notes
- Main page (`lib/screens/world_map_screen.dart`):
	- Shows continent cards with a mono/total label (e.g., `49/49`).
	- Inside each card countries are displayed in a responsive grid.
	- Country tile: centered flag with a small circular badge in the flag's corner showing number of saved images; name displayed beneath the flag.
- Add Banknote:
	- Image overlay buttons for camera/gallery/delete.
	- Save is a floating action button.
	- Two year-only pickers with `Present` option for circulation start/end.

## Known issues & TODOs
- Image-count detection is synchronous — switch to async/cached to avoid jank on large data sets.
- Flag emoji rendering varies across platforms (Android/iOS/desktop). Consider using image assets for consistent appearance.
- Minor analyzer warnings may remain (run `flutter analyze` and I can fix anything flagged).
- Badge currently shows `9+` for counts over 99 to fit layout. If you'd rather show `99+` I'll enlarge the badge.

## Contribution
- Fork the repo, create a feature branch, and submit a PR.
- Keep changes small and targeted; run `flutter analyze` and test on emulator/web/desktop as appropriate.
- If adding flag image assets, add them under `assets/flags/` and update `pubspec.yaml`.

## Testing
- No automated tests yet. Suggested minimal tests:
	- Unit test for `CountryData.fromJson()` to ensure asset parsing.
	- Widget test for `world_map_screen.dart` displaying a small list of countries.


## How to build release APK

```powershell
# Android release (after configuring signing configs)
flutter build apk --release
```
