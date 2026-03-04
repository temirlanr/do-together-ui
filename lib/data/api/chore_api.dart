import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/dtos.dart';

class ChoreApi {
  final ApiClient _client;
  ChoreApi(this._client);

  // ── Templates ──────────────────────────────────────────

  Future<List<ChoreTemplateDto>> getTemplates(String householdId) async {
    try {
      final response = await _client.dio
          .get('/api/households/$householdId/chores/templates');
      return (response.data as List<dynamic>)
          .map((e) => ChoreTemplateDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreTemplateDto> getTemplate(
      String householdId, String templateId) async {
    try {
      final response = await _client.dio
          .get('/api/households/$householdId/chores/templates/$templateId');
      return ChoreTemplateDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreTemplateDto> createTemplate(
      String householdId, CreateChoreTemplateDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/households/$householdId/chores/templates',
        data: dto.toJson(),
      );
      return ChoreTemplateDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreTemplateDto> updateTemplate(
      String householdId, String templateId, UpdateChoreTemplateDto dto) async {
    try {
      final response = await _client.dio.patch(
        '/api/households/$householdId/chores/templates/$templateId',
        data: dto.toJson(),
      );
      return ChoreTemplateDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<void> deleteTemplate(String householdId, String templateId) async {
    try {
      await _client.dio
          .delete('/api/households/$householdId/chores/templates/$templateId');
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<void> generateOccurrences(String householdId) async {
    try {
      await _client.dio.post('/api/households/$householdId/chores/generate');
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  // ── Occurrence Actions ─────────────────────────────────

  Future<ChoreOccurrenceDto> completeOccurrence(
      String householdId, String occurrenceId, MutationRequestDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/households/$householdId/chores/occurrences/$occurrenceId/complete',
        data: dto.toJson(),
      );
      return ChoreOccurrenceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreOccurrenceDto> undoOccurrence(
      String householdId, String occurrenceId, MutationRequestDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/households/$householdId/chores/occurrences/$occurrenceId/undo',
        data: dto.toJson(),
      );
      return ChoreOccurrenceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreOccurrenceDto> skipOccurrence(
      String householdId, String occurrenceId, MutationRequestDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/households/$householdId/chores/occurrences/$occurrenceId/skip',
        data: dto.toJson(),
      );
      return ChoreOccurrenceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<ChoreOccurrenceDto> reassignOccurrence(
      String householdId, String occurrenceId, ReassignRequestDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/households/$householdId/chores/occurrences/$occurrenceId/reassign',
        data: dto.toJson(),
      );
      return ChoreOccurrenceDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
