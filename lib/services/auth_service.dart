import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:smart_ventas/models/usuario.dart';

class AuthService {
  final firebase.FirebaseAuth _auth = firebase.FirebaseAuth.instance;

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
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
