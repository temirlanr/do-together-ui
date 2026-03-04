import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import '../dto/dtos.dart';

class DeviceApi {
  final ApiClient _client;
  DeviceApi(this._client);

  Future<void> registerDevice(RegisterDeviceDto dto) async {
    try {
      await _client.dio.post('/api/Devices', data: dto.toJson());
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }

  Future<void> unregisterDevice(RegisterDeviceDto dto) async {
    try {
      await _client.dio.delete('/api/Devices', data: dto.toJson());
    } on DioException catch (e) {
      throw _client.mapError(e);
    }
  }
}
