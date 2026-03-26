import '../entities/user.dart';

abstract class UserProvider {
  Future<User> getUser(String id);
}

class GetUserUseCase {
  GetUserUseCase(this._userProvider);

  final UserProvider _userProvider;

  Future<User> call(String id) {
    return _userProvider.getUser(id);
  }
}
