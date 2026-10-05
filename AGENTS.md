# Cartellino Notify

Flutter app (Android, iOS, Web) to track work hours, calculate shift end, and send local notifications. Features live countdown progress ring, manual/automatic start entry, and SQLite persistence.

## Core Functionality

-   Work End Calculation: `Shift End = Start Time + Work Duration + Lunch Break`
-   Minimum End Calculation: `Min End = Start Time + Min Time + Lunch Break`
    -   Start Time (HH:MM)
    -   Work Duration (Default: 07:12)
    -   Lunch Break (Default: 00:30)
    -   Min Time (Default: 06:00, configurable in settings — minimum to stay when recovering another day, less than full time)
    -   Core logic: `turnEndDateTime` / `minTurnEndDateTime` in `lib/services/cartellino_service.dart`
-   Automated Local Notifications:
    -   Min End: when minimum time is reached.
    -   Shift End: when work duration is reached.
    -   Liquidated Overtime: +30 min past shift end (liquidatable threshold).
-   Persistent Storage: local SQLite for settings and daily start times.

## Project Structure

```
lib/
├── main.dart                          # App entry point, sqflite web init, Provider setup
├── theme.dart                         # Design system (AppColors, gradients, ThemeData)
├── screens/
│   └── home_screen.dart               # Main dashboard with progress ring, info cards, action buttons
├── services/
│   ├── app_state.dart                 # ChangeNotifier state management, timer, recalculation (source of truth)
│   ├── cartellino_service.dart        # Pure Dart time calculation logic (port of cartellino.py)
│   ├── database_service.dart          # SQLite persistence layer (port of database.py)
│   └── notification_service.dart      # Local notification scheduling (replaces Telegram)
└── widgets/
    └── components.dart                # Reusable widgets: GlassCard, ProgressRing, GradientButton, etc.
```

Service-oriented: `services/` = business logic / DB / state, `screens/` = UI, `widgets/` = reusable components.

## Database Schema

-   `settings`: global configs (e.g. default `work_time`, `lunch_time`, `min_time`).
-   `user_settings`: daily values like `start_time` (keyed by `date`).

## Setup and Usage

Prerequisites: Flutter 3.x+, Android SDK / Xcode (mobile) or Chrome (web).

```bash
flutter pub get
flutter run # or flutter run -d chrome for web
flutter test
make apk # flutter build apk --split-per-abi
make web # flutter build web
```

## Tech Stack

-   Framework: Flutter (Dart)
-   State: `provider` + ChangeNotifier
-   Database: `sqflite` (+ `sqflite_common_ffi_web` for web, init in `main.dart`)
-   Notifications: `flutter_local_notifications`
-   Typography: `google_fonts` (Inter)
-   Time/Date: `intl`, `timezone`

## Conventions

-   Linting: `flutter_lints` via `analysis_options.yaml`.
-   Formatting: `flutter format .`
-   Time strings: always `HH:MM`.
