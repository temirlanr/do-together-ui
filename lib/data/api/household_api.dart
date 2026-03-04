import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/dtos.dart';

class HouseholdApi {
  final ApiClient _client;
  HouseholdApi(this._client);

  Future<List<HouseholdDto>> getHouseholds() async {
    try {
      final response = await _client.dio.get('/api/Households');
      return (response.data as List<dynamic>)
          .map((e) => HouseholdDto.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<HouseholdDto> getHousehold(String householdId) async {
    try {
      final response = await _client.dio.get('/api/Households/$householdId');
      return HouseholdDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<HouseholdDto> createHousehold(CreateHouseholdDto dto) async {
    try {
      final response =
          await _client.dio.post('/api/Households', data: dto.toJson());
      return HouseholdDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<InviteResponseDto> inviteMember(
      String householdId, InviteMemberDto dto) async {
    try {
      final response = await _client.dio.post(
        '/api/Households/$householdId/invites',
        data: dto.toJson(),
      );
      return InviteResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<HouseholdDto> joinHousehold(JoinHouseholdDto dto) async {
    try {
      final response =
          await _client.dio.post('/api/Households/join', data: dto.toJson());
      return HouseholdDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
