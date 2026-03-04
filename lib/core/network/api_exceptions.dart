/// Structured API error types for consistent handling.
class ApiException implements Exception {
  final int? statusCode;
  final String message;
  final dynamic data;

  const ApiException({this.statusCode, required this.message, this.data});

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException()
      : super(
            statusCode: 401, message: 'Session expired. Please log in again.');
}

class ConflictException extends ApiException {
  const ConflictException({String? message, dynamic data})
      : super(
            statusCode: 409,
            message: message ?? 'Conflict: data was modified by another user.',
            data: data);
}

class NetworkException extends ApiException {
  const NetworkException()
      : super(message: 'No internet connection. Changes saved locally.');
}

class ServerException extends ApiException {
  const ServerException({int? statusCode, String? message})
      : super(
            statusCode: statusCode ?? 500,
            message: message ?? 'Server error. Please try again later.');
}
