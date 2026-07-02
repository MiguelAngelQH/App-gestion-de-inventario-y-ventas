import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:http/http.dart' as http;
import 'package:smart_ventas/models/usuario.dart';

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;

  // Cambia esta URL por la de tu propio servidor/ngrok
  static const String _resetApiBaseUrl =
      'https://germinate-compress-try.ngrok-free.dev';

  Usuario? _mapUsuario(firebase.User? user) {
    if (user == null) return null;
    return Usuario(
      uid: user.uid,
      email: user.email ?? 'usuario@smartventas.app',
      nombre: user.displayName,
      fotoUrl: user.photoURL,
      fechaCreacion: user.metadata.creationTime,
    );
  }

  Usuario? get currentUser => _mapUsuario(_auth.currentUser);

  Stream<Usuario?> get authStateChanges =>
      _auth.authStateChanges().map(_mapUsuario);

  Future<void> registerWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    final uri = Uri.parse('$_resetApiBaseUrl/api/auth/send-reset-email');
    final response = await http
        .post(uri, headers: {'Content-Type': 'application/json'}, body: jsonEncode({'email': email.trim()}))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body);
      throw Exception(body['error'] ?? 'Error al enviar el correo');
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
