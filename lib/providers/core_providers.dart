import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../core/sync/sync_manager.dart';
import '../data/api/auth_api.dart';
import '../data/api/calendar_api.dart';
import '../data/api/chore_api.dart';
import '../data/api/device_api.dart';
import '../data/api/household_api.dart';

// ── Core singletons ───────────────────────────────────────

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  return ApiClient(storage);
});

// ── API services ──────────────────────────────────────────

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(apiClientProvider));
});

final householdApiProvider = Provider<HouseholdApi>((ref) {
  return HouseholdApi(ref.watch(apiClientProvider));
});

final choreApiProvider = Provider<ChoreApi>((ref) {
  return ChoreApi(ref.watch(apiClientProvider));
});

final calendarApiProvider = Provider<CalendarApi>((ref) {
  return CalendarApi(ref.watch(apiClientProvider));
});

final deviceApiProvider = Provider<DeviceApi>((ref) {
  return DeviceApi(ref.watch(apiClientProvider));
});

// ── Sync Manager ──────────────────────────────────────────

final syncManagerProvider = Provider<SyncManager>((ref) {
  final choreApi = ref.watch(choreApiProvider);
  final manager = SyncManager(choreApi);
  manager.startListening();
  ref.onDispose(() => manager.dispose());
  return manager;
});

final syncStatusProvider = StreamProvider<SyncStatus>((ref) {
  return ref.watch(syncManagerProvider).syncStatusStream;
});
