import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../../../core/storage/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider), ref.read(tokenStorageProvider));
});

class AuthRepository {
  AuthRepository(this._dio, this._storage);

  final Dio _dio;
  final TokenStorage _storage;

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/identity/auth/register', data: {
      'name': name,
      'email': email,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final res = await _dio.post('/identity/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = res.data as Map<String, dynamic>;
    await _storage.saveTokens(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String,
    );
  }

  Future<void> logout() async {
    await _storage.clearTokens();
  }

  Future<bool> isAuthenticated() => _storage.hasToken();
}
