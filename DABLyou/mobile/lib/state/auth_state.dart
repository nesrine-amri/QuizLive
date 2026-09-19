import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/token_storage.dart';

class AuthState {
  final String? token;
  const AuthState(this.token);
  bool get isAuthed => token != null && token!.isNotEmpty;
}

class AuthController extends StateNotifier<AuthState> {
  final TokenStorage storage;
  AuthController(this.storage) : super(const AuthState(null));

  Future<void> load() async {
    final t = await storage.read();
    state = AuthState(t);
  }

  Future<void> setToken(String token) async {
    await storage.write(token);
    state = AuthState(token);
  }

  Future<void> logout() async {
    await storage.clear();
    state = const AuthState(null);
  }
}

