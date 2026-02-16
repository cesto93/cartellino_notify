# Cartellino Notify

**Cartellino Notify** is a productivity tool designed to help users track their work hours, calculate when their work shift will end, and receive timely notifications. The name "Cartellino" refers to the Italian term for a work time card or clock-in card.

## 🚀 Project Overview

The project is a **Flutter mobile & web app** with a premium dark UI. Users can log their start time and receive local notifications when their shift ends or when they reach the "liquidated overtime" threshold.

## 🛠️ Core Functionality

-   **Work End Calculation**: Calculates the exact time a shift ends based on:
    -   Start Time (HH:MM)
    -   Work Duration (Default: 07:12)
    -   Lunch Break (Default: 00:30)
    -   Leisure Time (Optional HH:MM to subtract from work time)
-   **Automated Local Notifications**:
    -   **Shift End**: Notifies the user when the work duration is reached.
    -   **Liquidated Overtime**: Notifies when the user has exceeded the shift end by 30 minutes (the threshold for liquidatable overtime).
-   **Persistent Storage**: Uses a local SQLite database to store user settings and daily start times.

## 📁 Project Structure

```
lib/
├── main.dart                          # App entry point, sqflite web init, Provider setup
├── theme.dart                         # Design system (AppColors, gradients, ThemeData)
├── screens/
│   └── home_screen.dart               # Main dashboard with progress ring, info cards, action buttons
├── services/
│   ├── app_state.dart                 # ChangeNotifier state management, timer, recalculation
│   ├── cartellino_service.dart        # Pure Dart time calculation logic (port of cartellino.py)
│   ├── database_service.dart          # SQLite persistence layer (port of database.py)
│   └── notification_service.dart      # Local notification scheduling (replaces Telegram)
└── widgets/
    └── components.dart                # Reusable widgets: GlassCard, ProgressRing, GradientButton, etc.
```

## 📊 Database Schema

The system uses two main tables:
-   `settings`: Global configurations (e.g., default `work_time`, `lunch_time`).
-   `user_settings`: Store daily specific values like `start_time` and `leisure_time` (keyed by `date`).

## ⚙️ Setup and Usage

### Prerequisites
-   Flutter 3.x+
-   Android SDK / Xcode (for mobile) or Chrome (for web)

### Running the app
```bash
flutter pub get
flutter run
```

### Target platforms
-   Android
-   iOS
-   Web

## 🧰 Tech Stack

-   **Framework**: Flutter (Dart)
-   **State Management**: Provider + ChangeNotifier
-   **Database**: sqflite (+ sqflite_common_ffi_web for web)
-   **Notifications**: flutter_local_notifications
-   **Typography**: Google Fonts (Inter)
