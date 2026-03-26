class ApiService {
  Future<Map<String, dynamic>> fetchUser(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return {
      'id': id,
      'email': 'user@example.com',
      'name': 'Marketplace User',
    };
  }
}
