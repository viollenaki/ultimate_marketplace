class NoInternetConnectionException implements Exception {
  const NoInternetConnectionException();

  @override
  String toString() => 'No internet connection';
}

class BackendAuthException implements Exception {
  const BackendAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
