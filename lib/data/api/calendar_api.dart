import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/dtos.dart';

class CalendarApi {
  final ApiClient _client;
  CalendarApi(this._client);

  Future<List<DayAggregateDto>> getAggregates({
    required String householdId,
    required String from,
    required String to,
    String? assigneeId,
  }) async {
    try {
      final params = <String, dynamic>{'From': from, 'To': to};
      if (assigneeId != null) params['AssigneeId'] = assigneeId;

      final response = await _client.dio.get(
        '/api/households/$householdId/calendar/aggregates',
        queryParameters: params,
      );
      return (response.data as List<dynamic>)
          .map((e) => DayAggregateDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<List<ChoreOccurrenceDto>> getOccurrences({
    required String householdId,
    required String from,
    required String to,
    String? assigneeId,
  }) async {
    try {
      final params = <String, dynamic>{'From': from, 'To': to};
      if (assigneeId != null) params['AssigneeId'] = assigneeId;

      final response = await _client.dio.get(
        '/api/households/$householdId/calendar/occurrences',
        queryParameters: params,
      );
      return (response.data as List<dynamic>)
          .map((e) => ChoreOccurrenceDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
