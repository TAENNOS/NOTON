import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/repositories/auth_repository.dart';

enum AuthStatus { loading, authenticated, unauthenticated }

final authStatusProvider =
    StateNotifierProvider<AuthNotifier, AuthStatus>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthStatus> {
  AuthNotifier(this._repo) : super(AuthStatus.loading) {
    _init();
  }

  final AuthRepository _repo;

  Future<void> _init() async {
    final ok = await _repo.isAuthenticated();
    state = ok ? AuthStatus.authenticated : AuthStatus.unauthenticated;
  }

  Future<void> login(String email, String password) async {
    await _repo.login(email: email, password: password);
    state = AuthStatus.authenticated;
  }

  Future<void> register(String name, String email, String password) async {
    await _repo.register(name: name, email: email, password: password);
    state = AuthStatus.authenticated;
  }

  Future<void> logout() async {
    await _repo.logout();
    state = AuthStatus.unauthenticated;
  }
}
