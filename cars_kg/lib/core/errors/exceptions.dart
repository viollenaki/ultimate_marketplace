class AppException implements Exception {
  AppException(this.message);

  final String message;

  @override
  String toString() => 'AppException: $message';
}

class NetworkException extends AppException {
  NetworkException([String message = 'Network request failed']) : super(message);
}

class ValidationException extends AppException {
  ValidationException([String message = 'Validation failed']) : super(message);
}
