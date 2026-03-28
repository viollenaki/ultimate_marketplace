class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([super.message = 'Network request failed']);
}

class ValidationException extends AppException {
  ValidationException([super.message = 'Validation failed']);
}
