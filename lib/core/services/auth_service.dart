import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../models/user_model.dart';

class AuthService {
  SupabaseClient get _client => SupabaseService.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<UserModel?> register({
    required String email,
    required String password,
    required String role,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('No se pudo crear la cuenta. Intenta de nuevo.');
    }

    final userId = response.user!.id;

    // Small delay to ensure session is propagated
    await Future.delayed(const Duration(milliseconds: 300));

    try {
      await _client.from('users').upsert({
        'id': userId,
        'email': email,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('[AuthService] Error inserting user: $e');
      // Sign out and rethrow so UI can show the error
      await _client.auth.signOut();
      rethrow;
    }

    return _fetchUserModel(userId);
  }

  Future<UserModel?> login({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );

    if (response.user == null) {
      throw Exception('Credenciales inválidas. Verifica tu email y contraseña.');
    }

    return _fetchUserModel(response.user!.id);
  }

  Future<void> logout() async {
    await _client.auth.signOut();
  }

  Future<UserModel?> getCurrentUserModel() async {
    final user = currentUser;
    if (user == null) return null;
    return _fetchUserModel(user.id);
  }

  Future<UserModel?> _fetchUserModel(String userId) async {
    final data =
        await _client.from('users').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return UserModel.fromMap(data);
  }
}
