import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/achievement_dtos.dart';

class AchievementApi {
  final ApiClient _client;

  AchievementApi(this._client);

  Future<TodayWinsDto> getTodayWins({
    required String householdId,
    required AchievementScope scope,
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/households/$householdId/achievements/today',
        queryParameters: {'Scope': scope.value},
      );
      return TodayWinsDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<AchievementSummaryDto> getSummary({
    required String householdId,
    required AchievementScope scope,
    required String from, // "yyyy-MM-dd"
    required String to, // "yyyy-MM-dd"
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/households/$householdId/achievements/summary',
        queryParameters: {
          'Scope': scope.value,
          'From': from,
          'To': to,
        },
      );
      return AchievementSummaryDto.fromJson(
          response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<StreaksDto> getStreaks({
    required String householdId,
    required AchievementScope scope,
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/households/$householdId/achievements/streaks',
        queryParameters: {'Scope': scope.value},
      );
      return StreaksDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<BadgesResponseDto> getBadges({
    required String householdId,
    required AchievementScope scope,
  }) async {
    try {
      final response = await _client.dio.get(
        '/api/households/$householdId/achievements/badges',
        queryParameters: {'Scope': scope.value},
      );
      return BadgesResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
