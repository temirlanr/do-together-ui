import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';
import 'auth_interceptor.dart';

/// Central Dio HTTP client with auth handling and error mapping.
class ApiClient {
  late final Dio dio;
  late final Dio _refreshDio; // Separate instance for refresh calls
  final SecureStorage _storage;
  final Logger _log = Logger();

  /// Fires whenever the session is cleared due to auth failure.
  /// Listen to this to trigger logout in the UI layer.
  final StreamController<void> _sessionExpiredController =
      StreamController<void>.broadcast();
  Stream<void> get sessionExpiredStream => _sessionExpiredController.stream;

  ApiClient(this._storage) {
    _refreshDio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio = Dio(BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: AppConfig.connectTimeout,
      receiveTimeout: AppConfig.receiveTimeout,
      headers: {'Content-Type': 'application/json'},
    ));

    dio.interceptors.add(
      AuthInterceptor(
        _storage,
        _refreshDio,
        onSessionCleared: () => _sessionExpiredController.add(null),
      ),
    );

    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => _log.d(obj),
        ),
      );
    }
  }

  /// Maps DioException to typed ApiException.
  ApiException mapError(DioException e) {
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const NetworkException();
    }

    final status = e.response?.statusCode;
    if (status == 401) return const UnauthorizedException();
    if (status == 409) {
      return ConflictException(
        message: e.response?.data?['message'] as String?,
        data: e.response?.data,
      );
    }
    if (status != null && status >= 500) {
      return ServerException(statusCode: status);
    }

    return ApiException(
      statusCode: status,
      message: e.message ?? 'Unknown error',
    );
  }
}
