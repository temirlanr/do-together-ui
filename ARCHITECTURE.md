# DoTogether — Architecture

> Household chores productivity app for 2-person households.
> Flutter front-end backed by a .NET Web API.

---

## High-Level Architecture

```
┌────────────────────────────────────────────────────────────┐
│                      Flutter App                           │
│                                                            │
│  ┌──────────┐   ┌────────────┐   ┌──────────────────────┐ │
│  │   UI      │──▶│ Providers  │──▶│ API Services (Dio)   │─┼──▶ .NET Web API
│  │ (Screens) │   │ (Riverpod) │   └──────────────────────┘ │
│  └──────────┘   │            │                          │
│                  └────────────┘                          │
│                        │                                    │
│                        ▼                                    │
│               ┌────────────────┐                           │
│               │  SyncManager   │                           │
│               │ (API-first)    │                           │
│               └────────────────┘                           │
└────────────────────────────────────────────────────────────┘
```

---

## Folder Structure

```
lib/
├── main.dart                   # Entry point
├── app.dart                    # MaterialApp.router root widget
├── core/
│   ├── config/
│   │   ├── app_config.dart     # Base URL, timeouts, retry constants
│   │   └── app_theme.dart      # Material 3 light/dark themes
│   ├── network/
│   │   ├── api_client.dart     # Central Dio instance + error mapper
│   │   ├── auth_interceptor.dart  # Auto-attach Bearer token, 401 refresh
│   │   └── api_exceptions.dart # Typed exceptions (Network, Unauthorized, Conflict)
│   ├── storage/
│   │   └── secure_storage.dart # flutter_secure_storage wrapper for tokens/user
│   ├── sync/
│   │   └── sync_manager.dart   # API-first mutation dispatcher with status stream
│   ├── notifications/
│   │   └── notification_service.dart  # Local notifications via flutter_local_notifications
│   └── router/
│       └── app_router.dart     # GoRouter with auth guards
├── data/
│   ├── dto/
│   │   ├── dtos.dart           # All DTOs matching Swagger schema
│   │   └── enums.dart          # OccurrenceStatus, RecurrenceType, etc.
│   ├── api/
│   │   ├── auth_api.dart       # Magic-link auth endpoints
│   │   ├── household_api.dart  # Household CRUD + invite/join
│   │   ├── chore_api.dart      # Templates CRUD + occurrence mutations
│   │   ├── calendar_api.dart   # Day aggregates + occurrence queries
│   │   └── device_api.dart     # Push token registration
├── providers/
│   ├── core_providers.dart     # Singletons: ApiClient, API services, SyncManager
│   ├── auth_provider.dart      # AuthState + AuthNotifier
│   ├── household_provider.dart # HouseholdState + HouseholdNotifier
│   ├── chore_provider.dart     # Today, Upcoming, Templates notifiers
│   └── calendar_provider.dart  # CalendarNotifier (month aggregates, day selection)
└── ui/
    ├── auth/
    │   ├── login_screen.dart   # Email input → magic link
    │   └── verify_screen.dart  # Code verification
    ├── onboarding/
    │   └── household_setup_screen.dart  # Create or join household
    ├── today/
    │   └── today_screen.dart   # Overdue + today list with actions
    ├── upcoming/
    │   └── upcoming_screen.dart   # 7/14/30-day look-ahead
    ├── calendar/
    │   └── calendar_screen.dart   # Month view with day aggregates
    ├── templates/
    │   ├── templates_screen.dart   # Template list
    │   └── template_form_screen.dart  # Create/edit with recurrence
    ├── settings/
    │   └── settings_screen.dart   # User/household info, invite, notifications
    ├── home/
    │   └── home_shell.dart     # Bottom nav shell (5 tabs)
    └── widgets/
        ├── occurrence_tile.dart   # Reusable chore card with action buttons
        └── sync_status_banner.dart  # MaterialBanner for sync state
```

---

## Data Flow

### 1. Server -> App (Read Path)

```
.NET API  --HTTP-->  Api Service (Dio)  --DTO-->  Provider (Riverpod)
                                                         |
                                                         v
                                                   UI (Widgets)
```

1. **Provider** calls an **API service** (e.g., `ChoreApi.getOccurrences()`)
2. API service sends an HTTP request via **Dio** (with auth interceptor)
3. Response JSON is deserialized into **DTOs** (`ChoreOccurrenceDto`, etc.)
4. Provider updates its **state**, which triggers UI rebuild via Riverpod

### 2. App -> Server (Write Path / Mutations)

```
UI tap  -->  Provider  -->  SyncManager.enqueue*()
                                   |
                         Optimistic in-memory
                         state update (Provider)
                                   |
                                   v
                            API Service call
                                   |
                        Success: status -> synced
                        NetworkException: status -> offline, reverts state
                        UnauthorizedException: status -> authError
```

1. User taps an action (e.g., "Complete")
2. **Provider** optimistically updates its in-memory state for instant UI feedback
3. **Provider** calls `SyncManager.enqueueComplete(householdId, occurrenceId)`
4. SyncManager:
   - Generates a `clientOperationId` (UUID v4) for idempotency
   - Calls the API directly
   - Emits `syncing` -> `synced` on success
   - On failure, emits `offline` or `authError` and rethrows
5. If the API call fails, the **Provider** reverts its in-memory state

### 3. Sync Status

`SyncManager` exposes a `Stream<SyncStatus>` with values:
- `synced` -- no pending operations
- `syncing` -- API call in progress
- `offline` -- network error encountered
- `authError` -- token expired during a mutation
- `pending` / `conflict` -- reserved for future use

The `SyncStatusBanner` widget subscribes to this stream and shows the
appropriate banner at the top of every screen.

---

## API-First Design

| Concern | Implementation |
|---|---|
| **Reads** | Providers call API services directly. Data is held in Riverpod state only (no local DB). |
| **Writes** | All mutations go through `SyncManager` which calls the API immediately. On failure the provider reverts optimistic state. |
| **Idempotency** | Each mutation carries a `clientOperationId` (UUID). The server uses this to de-duplicate if the same operation arrives twice. |
| **Optimistic UI** | Providers update in-memory state before the API call, then revert on error. |
| **Error handling** | `NetworkException` -> status `offline`; `UnauthorizedException` -> status `authError`. Both rethrow so providers can react. |

---

## Authentication Flow

```
Email input  ──▶  POST /auth/magic-link  (sends email)
     │
     ▼
Verification screen  ──▶  POST /auth/verify  (code)
     │
     ▼
AuthResponseDto  ──▶  Save accessToken + refreshToken in SecureStorage
     │
     ▼
Redirect to app  (GoRouter auth guard)
```

- **Token refresh:** `AuthInterceptor` intercepts 401 responses, calls
  `POST /auth/refresh` with a separate Dio instance (no interceptors), saves
  new tokens, then retries the original request. All concurrent requests during
  refresh are queued and replayed after the new token is saved.

---

## State Management (Riverpod)

- **`Provider`** -- singletons: `SecureStorage`, `ApiClient`, API services, `SyncManager`
- **`StateNotifierProvider`** — stateful providers for each feature domain:
  - `authProvider` — auth status, login/verify/logout
  - `householdProvider` — current household, members, create/join
  - `todayOccurrencesProvider` — today + overdue items
  - `upcomingOccurrencesProvider` — configurable day range
  - `templateProvider` — CRUD templates
  - `calendarProvider` — month aggregates + day detail
- **`StreamProvider`** — `syncStatusProvider` for real-time sync UI

---

## Key Libraries

| Library | Purpose |
|---|---|
| `flutter_riverpod` | State management |
| `dio` | HTTP client |
| `go_router` | Declarative routing with auth guards |
| `flutter_secure_storage` | Encrypted token storage |
| `table_calendar` | Calendar month view |
| `flutter_local_notifications` | Local chore reminders |
| `uuid` | `clientOperationId` generation |
| `share_plus` | Sharing invite tokens |

---

## Edge Cases Handled

- **Overdue chores:** Today screen loads occurrences from the last 30 days and surfaces any still-pending past items in a separate "Overdue" section.
- **Duplicate taps:** Providers use `_isFetching` guards to prevent concurrent loads; mutations use `clientOperationId` for server-side idempotency.
- **Timezone awareness:** Household has a `timeZoneId`; dates are sent as `yyyy-MM-dd` strings; all timestamps are UTC.
- **Optimistic UI:** Status changes appear instantly in the UI via in-memory state updates, then get reverted if the API call fails.
- **Token expiry during sync:** SyncManager emits `authError` so the user can re-authenticate.
