abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic details;

  const AppException(this.message, {this.code, this.details});

  @override
  String toString() => 'AppException: $message';
}

class MediaStoreException extends AppException {
  const MediaStoreException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class PermissionException extends AppException {
  const PermissionException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class NetworkException extends AppException {
  const NetworkException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class CacheException extends AppException {
  const CacheException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class ValidationException extends AppException {
  const ValidationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}

class AuthenticationException extends AppException {
  const AuthenticationException(String message, {String? code, dynamic details})
      : super(message, code: code, details: details);
}
