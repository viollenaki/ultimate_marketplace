import '../../domain/entities/user.dart';
import '../../domain/usecases/get_user.dart';
import '../datasources/local/local_storage.dart';
import '../datasources/remote/api_service.dart';
import '../models/user_model.dart';

class UserRepository implements UserProvider {
  UserRepository({
    required ApiService apiService,
    required LocalStorage localStorage,
  })  : _apiService = apiService,
        _localStorage = localStorage;

  final ApiService _apiService;
  final LocalStorage _localStorage;

  @override
  Future<User> getUser(String id) async {
    final cached = await _localStorage.read(id);
    if (cached != null) {
      return UserModel.fromJson(cached);
    }

    final response = await _apiService.fetchUser(id);
    await _localStorage.save(id, response);
    return UserModel.fromJson(response);
  }
}
