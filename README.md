# DoTogether

A Flutter mobile app for 2-person household chores: create/assign chores, set reminders, track completions, and view a calendar/history of done vs missed.

## Prerequisites

- **Flutter SDK** ≥ 3.16.0 (stable channel)
- **Dart SDK** ≥ 3.2.0
- **Android Studio** or **VS Code** with Flutter extension
- An Android emulator / iOS simulator, or a physical device
- The [DoTogether .NET Web API](../do-together-api) running locally (or remotely)

## Getting Started

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Point to your local backend

By default the app connects to `http://10.0.2.2:5000` (the Android emulator's alias for `localhost`).

To override:

```bash
flutter run --dart-define=API_BASE_URL=http://YOUR_IP:5000
```

**Common values:**

| Platform | URL |
|---|---|
| Android emulator | `http://10.0.2.2:5000` (default) |
| iOS simulator | `http://localhost:5000` |
| Physical device | `http://YOUR_MACHINE_IP:5000` |

### 3. Run the app

```bash
flutter run
```

Or with a custom API URL:

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:5000
```

### 4. Run tests

```bash
# All tests
flutter test

# Widget tests only
flutter test test/widget/

# Integration tests
flutter test test/integration/
```

## Project Structure

```
lib/
├── main.dart              # Entry point
├── app.dart               # Root MaterialApp widget
├── core/                  # Config, networking, storage, sync, notifications, routing
├── data/                  # DTOs and API services
├── providers/             # Riverpod state management
└── ui/                    # Screens and widgets
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for a detailed architecture document describing data flow, offline-first design, and sync strategy.

## Screens

| Screen | Description |
|---|---|
| **Login** | Enter email to request a magic link |
| **Verify** | Enter the 6-digit code from the email |
| **Household Setup** | Create a new household or join with an invite token |
| **Today** | Overdue + today's chores with complete/undo/skip/reassign |
| **Upcoming** | Look-ahead view (7/14/30 days) |
| **Calendar** | Month view with per-day aggregate markers |
| **Templates** | List, create, edit, delete chore templates with recurrence |
| **Settings** | User info, household members, invite, notifications, sign out |

## Tech Stack

- **State management:** Riverpod (StateNotifier pattern)
- **Networking:** Dio with auth interceptor and automatic token refresh
- **Routing:** GoRouter with auth redirect guards
- **Calendar:** table_calendar
- **Notifications:** flutter_local_notifications
- **UI:** Material 3 with dynamic color theming

## Environment Variables

| Define | Default | Description |
|---|---|---|
| `API_BASE_URL` | `http://10.0.2.2:5000` | Backend API base URL |

Pass via `--dart-define=API_BASE_URL=...` at build/run time.

## License

Private — all rights reserved.
