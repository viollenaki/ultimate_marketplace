class LocalStorage {
  final Map<String, Map<String, dynamic>> _cache = {};

  Future<void> save(String key, Map<String, dynamic> value) async {
    _cache[key] = value;
  }

  Future<Map<String, dynamic>?> read(String key) async {
    return _cache[key];
  }
}
