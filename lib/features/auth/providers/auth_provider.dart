import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/models/user_model.dart';

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _userModel;
  String? _error;

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get error => _error;
  bool get isLoading => _status == AuthStatus.loading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    _authService.authStateChanges.listen((data) async {
      final event = data.event;
      if (event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.initialSession ||
          event == AuthChangeEvent.tokenRefreshed) {
        await _loadCurrentUser();
      } else if (event == AuthChangeEvent.signedOut) {
        _userModel = null;
        _status = AuthStatus.unauthenticated;
        notifyListeners();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      _userModel = await _authService.getCurrentUserModel();
      _status = _userModel != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
    } catch (_) {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
  }) async {
    _setLoading();
    try {
      _userModel = await _authService.register(
        email: email,
        password: password,
        role: role,
      );
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(_translateAuthError(e.message));
      return false;
    } on PostgrestException catch (e) {
      debugPrint('[AuthProvider] Postgrest register error: ${e.message} | ${e.code}');
      _setError(_translatePostgrestError(e));
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] register error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _userModel = await _authService.login(email: email, password: password);
      _status = AuthStatus.authenticated;
      _error = null;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _setError(_translateAuthError(e.message));
      return false;
    } on PostgrestException catch (e) {
      debugPrint('[AuthProvider] Postgrest login error: ${e.message}');
      _setError(_translatePostgrestError(e));
      return false;
    } catch (e) {
      debugPrint('[AuthProvider] login error: $e');
      _setError(e.toString().replaceAll('Exception: ', ''));
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _userModel = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  void updateUserModel(UserModel user) {
    _userModel = user;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _error = message;
    notifyListeners();
  }

  String _translatePostgrestError(PostgrestException e) {
    final code = e.code ?? '';
    final msg = e.message.toLowerCase();
    if (code == '42501' || msg.contains('policy')) {
      return 'Error de permisos en la base de datos. Verifica las políticas RLS en Supabase.';
    }
    if (code == '23505' || msg.contains('duplicate') || msg.contains('unique')) {
      return 'Este email ya está registrado.';
    }
    return 'Error de base de datos: ${e.message}';
  }

  String _translateAuthError(String message) {
    final msg = message.toLowerCase();
    if (msg.contains('user already registered') ||
        msg.contains('already been registered')) {
      return 'Este email ya está registrado. Inicia sesión.';
    }
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid credentials')) {
      return 'Email o contraseña incorrectos.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Debes confirmar tu email antes de ingresar.';
    }
    if (msg.contains('too many requests')) {
      return 'Demasiados intentos. Espera un momento.';
    }
    if (msg.contains('network')) {
      return 'Error de conexión. Verifica tu internet.';
    }
    return 'Ocurrió un error. Intenta de nuevo.';
  }
}
