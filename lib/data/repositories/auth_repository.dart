import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthRepository {
  AuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw translateAuthError(e.code);
    }
  }

  Future<UserCredential> registerWithEmail(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw translateAuthError(e.code);
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await GoogleSignIn.instance.initialize();
      final account = await GoogleSignIn.instance.authenticate();
      final authHeaders = account.authentication;
      final idToken = authHeaders.idToken;
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      throw translateAuthError(e.code);
    } catch (_) {
      throw 'Google ile giriş yapılırken bir sorun oluştu.';
    }
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    await _auth.signOut();
  }

  static String translateAuthError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'E-posta adresi geçersiz.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'E-posta veya şifre hatalı.';
      case 'email-already-in-use':
        return 'Bu e-posta ile zaten bir hesap var.';
      case 'weak-password':
        return 'Şifre en az 6 karakter olmalı.';
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      default:
        return 'Bir şeyler ters gitti, lütfen tekrar dene ($code).';
    }
  }
}
