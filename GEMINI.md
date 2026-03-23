# Cartellino Notify - Project Context

## Project Overview
**Cartellino Notify** is a Flutter-based application designed to track work hours, calculate shift end times, and provide local notifications. The app supports Android, iOS, and Web platforms. It features a live countdown progress ring, manual and automatic start time entry, and persistence via SQLite.

### Core Calculation Logic
The shift end time is calculated as follows:
`Shift End = Start Time + Work Duration + Lunch Break - Leisure Time`

### Key Technologies
- **Framework**: Flutter (Dart)
- **State Management**: `provider` (ChangeNotifier)
- **Database**: `sqflite` (with `sqflite_common_ffi_web` for web support)
- **Notifications**: `flutter_local_notifications`
- **Typography**: `google_fonts` (Inter)
- **Time/Date**: `intl`, `timezone`

## Building and Running
The project follows standard Flutter commands, with some shortcuts provided in the `Makefile`.

### Key Commands
- **Install Dependencies**: `flutter pub get`
- **Run App**: `flutter run` (or `flutter run -d chrome` for web)
- **Build APK**: `make apk` (runs `flutter build apk --split-per-abi`)
- **Build Web**: `make web` (runs `flutter build web`)
- **Run Tests**: `flutter test`

## Development Conventions

### Architecture
The project follows a service-oriented architecture:
- **`lib/services/`**: Contains business logic, database interaction, and state management.
  - `app_state.dart`: Central state management using `ChangeNotifier`.
  - `cartellino_service.dart`: Pure logic for time calculations (port of `cartellino.py`).
  - `database_service.dart`: Handles SQLite persistence for settings and daily entries.
  - `notification_service.dart`: Manages local notifications for shift end and overtime.
- **`lib/screens/`**: UI screens (e.g., `home_screen.dart`).
- **`lib/widgets/`**: Reusable UI components.
- **`lib/theme.dart`**: Centralized styling, colors, and gradients.

### Coding Standards
- **Linting**: Uses `package:flutter_lints/flutter.yaml`.
- **Formatting**: Use `flutter format .` to maintain consistent code style.
- **Time Format**: All time-related strings follow the `HH:MM` format.
- **Web Support**: Web-specific database initialization is handled in `main.dart` using `sqflite_common_ffi_web`.

## Key Files
- `pubspec.yaml`: Project metadata and dependencies.
- `lib/main.dart`: Entry point and global provider initialization.
- `lib/services/cartellino_service.dart`: Contains the core `turnEndDateTime` logic.
- `lib/services/app_state.dart`: The source of truth for the application state.
- `Makefile`: Useful build shortcuts.
- `analysis_options.yaml`: Linting configuration.
