import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/dtos.dart';

class AuthApi {
  final ApiClient _client;
  AuthApi(this._client);

  /// Register a new account.
  Future<AuthResponseDto> register(RegisterDto dto) async {
    try {
      final response =
          await _client.dio.post('/api/Auth/register', data: dto.toJson());
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  /// Login with email + password.
  Future<AuthResponseDto> login(LoginDto dto) async {
    try {
      final response =
          await _client.dio.post('/api/Auth/login', data: dto.toJson());
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  /// Refresh access token.
  Future<AuthResponseDto> refresh(RefreshRequestDto dto) async {
    try {
      final response =
          await _client.dio.post('/api/Auth/refresh', data: dto.toJson());
      return AuthResponseDto.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
