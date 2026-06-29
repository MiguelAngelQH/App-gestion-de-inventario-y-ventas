import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/widgets.dart';
import 'package:smart_ventas/models/usuario.dart';
import 'package:smart_ventas/services/auth_service.dart';

enum AuthStatus { uninitialized, authenticated, unauthenticated, loading }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.uninitialized;
  Usuario? _usuario;
  String? _error;
  bool _isLoading = false;
  bool _disposed = false;
  StreamSubscription? _authSub;

  AuthStatus get status => _status;
  Usuario? get usuario => _usuario;
  String? get error => _error;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthViewModel() {
    _authSub = _authService.authStateChanges.listen((usuario) {
      _usuario = usuario;
      _status = usuario != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated;
      _safeNotify();
    });
  }

  void _safeNotify() {
    if (!_disposed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_disposed) notifyListeners();
      });
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _status = AuthStatus.loading;
    _safeNotify();

    try {
      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _error = null;
      _isLoading = false;
      _safeNotify();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      _isLoading = false;
      _status = AuthStatus.unauthenticated;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      _isLoading = false;
      _status = AuthStatus.unauthenticated;
      _safeNotify();
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _error = null;
    _status = AuthStatus.loading;
    _safeNotify();

    try {
      await _authService.registerWithEmailAndPassword(
        email: email,
        password: password,
      );
      _error = null;
      _isLoading = false;
      _safeNotify();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      _isLoading = false;
      _status = AuthStatus.unauthenticated;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      _isLoading = false;
      _status = AuthStatus.unauthenticated;
      _safeNotify();
      return false;
    }
  }

  Future<bool> resetPassword({required String email}) async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      await _authService.sendPasswordResetEmail(email: email);
      _isLoading = false;
      _safeNotify();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapFirebaseError(e);
      _isLoading = false;
      _safeNotify();
      return false;
    } catch (e) {
      _error = 'Error de conexión. Verifica tu internet.';
      _isLoading = false;
      _safeNotify();
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.signOut();
  }

  void clearError() {
    _error = null;
    _safeNotify();
  }

  @override
  void dispose() {
    _disposed = true;
    _authSub?.cancel();
    super.dispose();
  }

  String _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No existe una cuenta con este correo.';
      case 'wrong-password':
        return 'Contraseña incorrecta.';
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'invalid-email':
        return 'El formato del correo no es válido.';
      case 'user-disabled':
        return 'Esta cuenta ha sido deshabilitada.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con este correo.';
      case 'operation-not-allowed':
        return 'El inicio de sesión no está habilitado.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Intenta más tarde.';
      case 'network-request-failed':
        return 'Error de conexión. Verifica tu internet.';
      default:
        return 'Error: ${e.message ?? e.code}';
    }
  }
}
