class NoInternetConnectionException implements Exception {
  const NoInternetConnectionException();

  @override
  String toString() => 'No internet connection';
}

class BackendAuthException implements Exception {
  const BackendAuthException(this.message, {this.httpStatus});

  final String message;
  final int? httpStatus;

  @override
  String toString() => message;
}
