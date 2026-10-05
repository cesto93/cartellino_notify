# Cartellino Notify

**Cartellino Notify** is a Flutter app that helps you track your work hours, calculate when your shift ends, and receive local notifications. The name "Cartellino" refers to the Italian term for a work time card / clock-in card.

## 🚀 Features

- **"I'm Arrived" button** — Sets start time to the current time
- **Manual Start Time** — Enter a custom start time in HH:MM format
- **Live Countdown** — Real-time progress ring showing shift progress
- **Work End Calculation** — Based on start time, work duration, and lunch break
- **Minimum Time** — Configurable min time for early leave when recovering another day
- **Overtime Tracking** — Detects overtime and liquidatable overtime (30+ min after shift end)
- **Local Notifications** — Get notified at min end, shift end, and when overtime becomes liquidatable
- **Persistent Storage** — SQLite database stores your settings across sessions
- **Settings** — Configure default work duration, lunch break, and min time

## 🛠️ Core Calculation

The app calculates shift end as:

```
Shift End = Start Time + Work Duration + Lunch Break
Min End   = Start Time + Min Time + Lunch Break
```

Defaults:
- **Work Duration**: 07:12
- **Lunch Break**: 00:30
- **Min Time**: 06:00 (minimum to stay when recovering another day, less than full time)

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point
├── theme.dart                         # Design system (colors, gradients, theme)
├── screens/
│   └── home_screen.dart               # Main UI with progress ring & actions
├── services/
│   ├── app_state.dart                 # ChangeNotifier state management
│   ├── cartellino_service.dart        # Time calculation logic
│   ├── database_service.dart          # SQLite persistence
│   └── notification_service.dart      # Local notifications
└── widgets/
    └── components.dart                # Reusable UI components
```

## 📊 Database Schema

- **`settings`** — Global config (work_time, lunch_time, min_time)
- **`user_settings`** — Daily values (start_time) keyed by date

## ⚙️ Setup

### Prerequisites
- Flutter 3.x+
- Android SDK / Xcode (for mobile) or Chrome (for web)

### Running
```bash
flutter pub get
flutter run             # Run on connected device/emulator
flutter run -d chrome   # Run on web
flutter run -d android  # Run on Android
flutter run -d ios      # Run on iOS
```

## 🧰 Tech Stack

- **Framework**: Flutter (Dart)
- **State Management**: Provider + ChangeNotifier
- **Database**: sqflite (+ sqflite_common_ffi_web for web)
- **Notifications**: flutter_local_notifications
- **Typography**: Google Fonts (Inter)
- **Platforms**: Android, iOS, Web
