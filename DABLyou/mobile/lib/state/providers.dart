import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_client.dart';
import '../core/token_storage.dart';
import 'auth_state.dart';

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ref.watch(tokenStorageProvider));
});

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(authControllerProvider).token;
  return ApiClient(token: token);
});

