import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

import '../core/network/api_exceptions.dart';
import '../data/api/achievement_api.dart';
import '../data/dto/achievement_dtos.dart';
import 'core_providers.dart';
import 'household_provider.dart';

// ── Cache key helpers ─────────────────────────────────────

const _kCachePrefix = 'achievements_cache_';
const _kTimestampSuffix = '_ts';

String _cacheKey(AchievementScope scope) => '$_kCachePrefix${scope.value}';
String _tsKey(AchievementScope scope) =>
    '${_cacheKey(scope)}$_kTimestampSuffix';

// ── State ─────────────────────────────────────────────────

class AchievementsData {
  final TodayWinsDto todayWins;
  final AchievementSummaryDto summary;
  final StreaksDto streaks;
  final BadgesResponseDto badges;

  const AchievementsData({
    required this.todayWins,
    required this.summary,
    required this.streaks,
    required this.badges,
  });

  /// True if there have been zero completions ever across all sections.
  bool get isEmpty =>
      todayWins.completedCountToday == 0 &&
      summary.totalCompleted == 0 &&
      streaks.currentStreakDays == 0 &&
      badges.earnedBadges.isEmpty;

  Map<String, dynamic> toJson() => {
        'todayWins': todayWins.toJson(),
        'summary': summary.toJson(),
        'streaks': streaks.toJson(),
        'badges': badges.toJson(),
      };

  factory AchievementsData.fromJson(Map<String, dynamic> json) =>
      AchievementsData(
        todayWins:
            TodayWinsDto.fromJson(json['todayWins'] as Map<String, dynamic>),
        summary: AchievementSummaryDto.fromJson(
            json['summary'] as Map<String, dynamic>),
        streaks: StreaksDto.fromJson(json['streaks'] as Map<String, dynamic>),
        badges:
            BadgesResponseDto.fromJson(json['badges'] as Map<String, dynamic>),
      );
}

class AchievementsState {
  final bool isLoading;
  final AchievementScope scope;
  final AchievementsData? data;
  final String? error;
  final DateTime? lastUpdated;
  final bool isFromCache;

  const AchievementsState({
    this.isLoading = false,
    this.scope = AchievementScope.household,
    this.data,
    this.error,
    this.lastUpdated,
    this.isFromCache = false,
  });

  AchievementsState copyWith({
    bool? isLoading,
    AchievementScope? scope,
    AchievementsData? data,
    String? error,
    DateTime? lastUpdated,
    bool? isFromCache,
  }) {
    return AchievementsState(
      isLoading: isLoading ?? this.isLoading,
      scope: scope ?? this.scope,
      data: data ?? this.data,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isFromCache: isFromCache ?? this.isFromCache,
    );
  }
}

// ── Notifier ──────────────────────────────────────────────

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  final AchievementApi _api;
  final String _householdId;
  final FlutterSecureStorage _cache;
  bool _isFetching = false;

  AchievementsNotifier(this._api, this._householdId)
      : _cache = const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true)),
        super(const AchievementsState());

  // ── Public actions ─────────────────────────

  Future<void> load() {
    if (_isFetching) return Future.value();
    return _fetch(state.scope);
  }

  Future<void> refresh() => _fetch(state.scope);

  void setScope(AchievementScope scope) {
    if (scope == state.scope) return;
    state = state.copyWith(scope: scope, isLoading: true, error: null);
    _fetch(scope);
  }

  // ── Internal ───────────────────────────────

  Future<void> _fetch(AchievementScope scope) async {
    if (_householdId.isEmpty) return;
    _isFetching = true;
    state = state.copyWith(isLoading: true, error: null);

    // Build current week window (Monday–today)
    final now = DateTime.now();
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final fmt = DateFormat('yyyy-MM-dd');
    final from = fmt.format(monday);
    final to = fmt.format(now);

    try {
      final results = await Future.wait([
        _api.getTodayWins(householdId: _householdId, scope: scope),
        _api.getSummary(
            householdId: _householdId, scope: scope, from: from, to: to),
        _api.getStreaks(householdId: _householdId, scope: scope),
        _api.getBadges(householdId: _householdId, scope: scope),
      ]);

      final data = AchievementsData(
        todayWins: results[0] as TodayWinsDto,
        summary: results[1] as AchievementSummaryDto,
        streaks: results[2] as StreaksDto,
        badges: results[3] as BadgesResponseDto,
      );

      await _persistCache(scope, data);

      state = state.copyWith(
        isLoading: false,
        scope: scope,
        data: data,
        lastUpdated: DateTime.now(),
        isFromCache: false,
      );
    } on ApiException catch (e) {
      final cached = await _loadCache(scope);
      if (cached != null) {
        state = state.copyWith(
          isLoading: false,
          scope: scope,
          data: cached.data,
          lastUpdated: cached.lastUpdated,
          isFromCache: true,
          error: e.message,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          scope: scope,
          error: e.message,
        );
      }
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _persistCache(
      AchievementScope scope, AchievementsData data) async {
    try {
      await Future.wait([
        _cache.write(key: _cacheKey(scope), value: jsonEncode(data.toJson())),
        _cache.write(
            key: _tsKey(scope), value: DateTime.now().toIso8601String()),
      ]);
    } catch (_) {
      // Cache write failure is non-fatal
    }
  }

  Future<({AchievementsData data, DateTime lastUpdated})?> _loadCache(
      AchievementScope scope) async {
    try {
      final json = await _cache.read(key: _cacheKey(scope));
      final ts = await _cache.read(key: _tsKey(scope));
      if (json == null || ts == null) return null;

      final data =
          AchievementsData.fromJson(jsonDecode(json) as Map<String, dynamic>);
      final lastUpdated = DateTime.parse(ts);
      return (data: data, lastUpdated: lastUpdated);
    } catch (_) {
      return null;
    }
  }
}

// ── Providers ─────────────────────────────────────────────

final achievementApiProvider = Provider<AchievementApi>((ref) {
  return AchievementApi(ref.watch(apiClientProvider));
});

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>((ref) {
  final householdId = ref.watch(currentHouseholdIdProvider) ?? '';
  return AchievementsNotifier(
    ref.watch(achievementApiProvider),
    householdId,
  );
});
