import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSessionStorage extends LocalStorage {
  const SecureSessionStorage(this.namespace);
  final String namespace;
  static const storage = FlutterSecureStorage();
  String get key => 'gainly.session.$namespace';
  @override
  Future<void> initialize() async {}
  @override
  Future<bool> hasAccessToken() => storage.containsKey(key: key);
  @override
  Future<String?> accessToken() => storage.read(key: key);
  @override
  Future<void> persistSession(String persistSessionString) =>
      storage.write(key: key, value: persistSessionString);
  @override
  Future<void> removePersistedSession() => storage.delete(key: key);
}

class SecurePkceStorage extends GotrueAsyncStorage {
  SecurePkceStorage(this.namespace);
  final String namespace;
  static const storage = FlutterSecureStorage();
  String namespaced(String key) => 'gainly.pkce.$namespace.$key';
  @override
  Future<String?> getItem({required String key}) =>
      storage.read(key: namespaced(key));
  @override
  Future<void> removeItem({required String key}) =>
      storage.delete(key: namespaced(key));
  @override
  Future<void> setItem({required String key, required String value}) =>
      storage.write(key: namespaced(key), value: value);
}
