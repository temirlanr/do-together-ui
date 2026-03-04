import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/api_exceptions.dart';
import '../core/storage/secure_storage.dart';
import '../data/api/household_api.dart';
import '../data/dto/dtos.dart';
import 'core_providers.dart';

class HouseholdState {
  final bool isLoading;
  final HouseholdDto? household;
  final List<HouseholdDto> households;
  final String? error;

  const HouseholdState({
    this.isLoading = false,
    this.household,
    this.households = const [],
    this.error,
  });

  HouseholdState copyWith({
    bool? isLoading,
    HouseholdDto? household,
    List<HouseholdDto>? households,
    String? error,
  }) {
    return HouseholdState(
      isLoading: isLoading ?? this.isLoading,
      household: household ?? this.household,
      households: households ?? this.households,
      error: error,
    );
  }

  bool get hasHousehold => household != null;
}

class HouseholdNotifier extends StateNotifier<HouseholdState> {
  final HouseholdApi _api;
  final SecureStorage _storage;

  HouseholdNotifier(this._api, this._storage) : super(const HouseholdState());

  /// Load households for the current user.
  Future<void> loadHouseholds() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final households = await _api.getHouseholds();
      state = state.copyWith(isLoading: false, households: households);

      if (households.isNotEmpty) {
        // Use the first household by default (2-person app)
        final household = households.first;
        await selectHousehold(household);
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> selectHousehold(HouseholdDto household) async {
    await _storage.saveHouseholdId(household.id);
    state = state.copyWith(household: household);
  }

  /// Create a new household.
  Future<bool> createHousehold(String name, String timeZoneId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final household = await _api.createHousehold(
        CreateHouseholdDto(name: name, timeZoneId: timeZoneId),
      );
      await selectHousehold(household);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Join a household with invite token.
  Future<bool> joinHousehold(String inviteToken) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final household = await _api.joinHousehold(
        JoinHouseholdDto(inviteToken: inviteToken),
      );
      await selectHousehold(household);
      state = state.copyWith(isLoading: false);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  /// Invite a member by email.
  Future<InviteResponseDto?> inviteMember(String email) async {
    if (state.household == null) return null;
    try {
      return await _api.inviteMember(
        state.household!.id,
        InviteMemberDto(email: email),
      );
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return null;
    }
  }

  /// Refresh household details from server.
  Future<void> refreshHousehold() async {
    if (state.household == null) return;
    try {
      final household = await _api.getHousehold(state.household!.id);
      state = state.copyWith(household: household);
    } on ApiException catch (_) {
      // Keep existing data on error
    }
  }
}

final householdProvider =
    StateNotifierProvider<HouseholdNotifier, HouseholdState>((ref) {
  return HouseholdNotifier(
    ref.watch(householdApiProvider),
    ref.watch(secureStorageProvider),
  );
});

/// Convenient accessor for the current household ID.
final currentHouseholdIdProvider = Provider<String?>((ref) {
  return ref.watch(householdProvider).household?.id;
});
