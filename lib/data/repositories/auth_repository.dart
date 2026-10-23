import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/local_storage_service.dart';

class AuthUserProxy {
  final String uid;
  final String? email;
  const AuthUserProxy({required this.uid, this.email});
}

class AuthResult {
  final String uid;
  final String? email;
  final User? firebaseUser;

  const AuthResult({
    required this.uid,
    this.email,
    this.firebaseUser,
  });

  AuthUserProxy? get user => AuthUserProxy(uid: uid, email: email);
}

class AuthRepository {
  AuthRepository([this._auth]) {
    _localUid ??= LocalStorageService.instance.getSessionUid();
    final firebaseAuth = _safeAuth;
    if (firebaseAuth != null) {
      try {
        firebaseAuth.authStateChanges().listen((user) {
          if (user != null) {
            _localUid = user.uid;
            _uidStreamController.add(user.uid);
            // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
            authChangeNotifier.notifyListeners();
          }
        });
      } catch (_) {}
    }
  }

  final FirebaseAuth? _auth;

  FirebaseAuth? get _safeAuth {
    if (_auth != null) return _auth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  static String? _localUid;
  static final ChangeNotifier authChangeNotifier = ChangeNotifier();
  static final StreamController<String?> _uidStreamController =
      StreamController<String?>.broadcast();

  Stream<User?> authStateChanges() =>
      _safeAuth?.authStateChanges() ?? const Stream.empty();

  Stream<String?> authUidChanges() async* {
    yield currentUid;
    yield* _uidStreamController.stream;
  }

  User? get currentUser => _safeAuth?.currentUser;

  String? get currentUid => _localUid ?? _safeAuth?.currentUser?.uid;

  static String? get currentSessionUid => _localUid;

  static bool isLocalUid(String uid) {
    return uid.startsWith('local_') || uid.startsWith('guest_');
  }

  Future<void> _setLocalSession(String? uid) async {
    _localUid = uid;
    await LocalStorageService.instance.saveSessionUid(uid);
    _uidStreamController.add(uid);
    // ignore: invalid_use_of_visible_for_testing_member, invalid_use_of_protected_member
    authChangeNotifier.notifyListeners();
  }

  Future<AuthResult> signInWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // 1. Check if account was registered locally
    final localUser = LocalStorageService.instance.getRegisteredUser(cleanEmail);
    if (localUser != null) {
      if (localUser['password'] == cleanPassword) {
        final uid = localUser['uid'] as String;
        await _setLocalSession(uid);
        return AuthResult(uid: uid, email: cleanEmail);
      } else {
        throw 'E-posta veya şifre hatalı.';
      }
    }

    // 2. Try Firebase Auth if available
    final auth = _safeAuth;
    if (auth != null) {
      try {
        final cred = await auth.signInWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final uid = cred.user!.uid;
        await _setLocalSession(uid);
        return AuthResult(uid: uid, email: cleanEmail, firebaseUser: cred.user);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' ||
            e.code == 'wrong-password' ||
            e.code == 'invalid-credential') {
          throw 'E-posta veya şifre hatalı.';
        }
      } catch (_) {}
    }

    throw 'Giriş yapılamadı. Kayıtlı hesabın yoksa önce Kayıt Ol ekranından hesap oluşturabilirsin.';
  }

  Future<AuthResult> registerWithEmail(String email, String password) async {
    final cleanEmail = email.trim();
    final cleanPassword = password.trim();

    // 1. Try Firebase Auth first if available
    final auth = _safeAuth;
    if (auth != null) {
      try {
        final cred = await auth.createUserWithEmailAndPassword(
          email: cleanEmail,
          password: cleanPassword,
        );
        final uid = cred.user!.uid;
        await _setLocalSession(uid);
        return AuthResult(uid: uid, email: cleanEmail, firebaseUser: cred.user);
      } catch (e) {
        debugPrint('Firebase registration failed, saving locally: $e');
      }
    }

    // 2. Fall back to local registration
    if (LocalStorageService.instance.isEmailRegistered(cleanEmail)) {
      throw 'Bu e-posta ile zaten kayıtlı bir hesap var.';
    }

    final sanitizedEmail = cleanEmail.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final localUid = 'local_${sanitizedEmail}_${DateTime.now().millisecondsSinceEpoch}';

    await LocalStorageService.instance.saveRegisteredUser(
      uid: localUid,
      email: cleanEmail,
      password: cleanPassword,
    );

    await _setLocalSession(localUid);
    return AuthResult(uid: localUid, email: cleanEmail);
  }

  Future<AuthResult?> signInWithGoogle() async {
    final auth = _safeAuth;
    if (auth != null) {
      try {
        await GoogleSignIn.instance.initialize();
        final account = await GoogleSignIn.instance.authenticate();
        final authHeaders = account.authentication;
        final idToken = authHeaders.idToken;
        final credential = GoogleAuthProvider.credential(idToken: idToken);
        final cred = await auth.signInWithCredential(credential);
        final uid = cred.user!.uid;
        await _setLocalSession(uid);
        return AuthResult(uid: uid, email: cred.user?.email, firebaseUser: cred.user);
      } catch (_) {}
    }

    // Fallback guest login on web if google sign-in fails
    final guestUid = 'guest_google_${DateTime.now().millisecondsSinceEpoch}';
    await _setLocalSession(guestUid);
    return AuthResult(uid: guestUid);
  }

  Future<AuthResult> signInAnonymously() async {
    final auth = _safeAuth;
    if (auth != null) {
      try {
        final cred = await auth.signInAnonymously();
        final uid = cred.user!.uid;
        await _setLocalSession(uid);
        return AuthResult(uid: uid, firebaseUser: cred.user);
      } catch (e) {
        debugPrint('Firebase anonymous login fallback to local guest: $e');
      }
    }

    final guestUid = 'guest_${DateTime.now().millisecondsSinceEpoch}';
    await _setLocalSession(guestUid);
    return AuthResult(uid: guestUid);
  }

  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.disconnect();
    } catch (_) {}
    try {
      await _safeAuth?.signOut();
    } catch (_) {}
    await _setLocalSession(null);
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
      case 'operation-not-allowed':
        return 'Bu giriş yöntemi Firebase Console üzerinde etkinleştirilmemiş.';
      case 'network-request-failed':
        return 'İnternet bağlantını kontrol et.';
      default:
        return 'Bir şeyler ters gitti, lütfen tekrar dene ($code).';
    }
  }
}
