import 'package:dio/dio.dart';
import 'package:logger/logger.dart';
import '../storage/secure_storage.dart';
import 'api_exceptions.dart';

/// Dio interceptor that attaches Bearer token and handles 401 refresh.
class AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  final Dio _dio; // A separate Dio instance for refresh to avoid recursion
  final void Function()? onSessionCleared;
  final Logger _log = Logger();
  bool _isRefreshing = false;
  final List<({RequestOptions options, ErrorInterceptorHandler handler})>
      _pendingRequests = [];

  AuthInterceptor(this._storage, this._dio, {this.onSessionCleared});

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _storage.accessToken;
    if (token != null) {
      // Proactively refresh if token expires within the next 30 seconds
      final expires = await _storage.expiresAtUtc;
      final expiresWithBuffer = expires?.subtract(const Duration(seconds: 30));
      final isExpiringSoon = expiresWithBuffer != null &&
          expiresWithBuffer.isBefore(DateTime.now().toUtc());

      if (isExpiringSoon && !_isRefreshing) {
        try {
          final newToken = await _refreshTokens();
          options.headers['Authorization'] = 'Bearer $newToken';
          handler.next(options);
          return;
        } catch (_) {
          // Refresh failed — clear session and reject
          await _clearSession();
          handler.reject(DioException(
            requestOptions: options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: options,
              statusCode: 401,
            ),
          ));
          return;
        }
      }

      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      if (_isRefreshing) {
        // Queue request while refresh is in progress
        _pendingRequests.add((options: err.requestOptions, handler: handler));
        return;
      }

      _isRefreshing = true;

      try {
        final newAccessToken = await _refreshTokens();
        _isRefreshing = false;

        // Retry the original request
        err.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
        final retryResponse = await _dio.fetch(err.requestOptions);
        handler.resolve(retryResponse);

        // Retry queued requests
        for (final pending in _pendingRequests) {
          pending.options.headers['Authorization'] = 'Bearer $newAccessToken';
          try {
            final r = await _dio.fetch(pending.options);
            pending.handler.resolve(r);
          } catch (e) {
            pending.handler.reject(
                DioException(requestOptions: pending.options, error: e));
          }
        }
        _pendingRequests.clear();
      } catch (e) {
        _isRefreshing = false;
        // Reject all pending requests
        for (final pending in _pendingRequests) {
          pending.handler.reject(DioException(
            requestOptions: pending.options,
            type: DioExceptionType.badResponse,
            response: Response(
              requestOptions: pending.options,
              statusCode: 401,
            ),
          ));
        }
        _pendingRequests.clear();
        _log.e('Token refresh failed', error: e);
        // Clear session so the router redirects to login
        await _clearSession();
        handler.reject(DioException(
          requestOptions: err.requestOptions,
          type: DioExceptionType.badResponse,
          response: Response(
            requestOptions: err.requestOptions,
            statusCode: 401,
          ),
        ));
      }
    } else {
      handler.next(err);
    }
  }

  /// Performs the token refresh and stores new tokens. Returns the new access token.
  Future<String> _refreshTokens() async {
    final refreshToken = await _storage.refreshToken;
    if (refreshToken == null) throw const UnauthorizedException();

    final response = await _dio.post(
      '/api/Auth/refresh',
      data: {'refreshToken': refreshToken},
    );

    final newAccessToken = response.data['accessToken'] as String;
    final newRefreshToken = response.data['refreshToken'] as String;
    final expiresAt = DateTime.parse(response.data['expiresAtUtc'] as String);

    await _storage.saveTokens(
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
      expiresAtUtc: expiresAt,
    );

    return newAccessToken;
  }

  /// Clears all stored tokens so the router redirects to login on next evaluation.
  Future<void> _clearSession() async {
    try {
      await _storage.clearAll();
      onSessionCleared?.call();
    } catch (_) {}
  }
}
