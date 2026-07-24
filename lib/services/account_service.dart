import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AccountService extends ChangeNotifier {
  AccountService({required this.firebaseReady});

  final bool firebaseReady;
  bool _googleInitialized = false;
  String? errorMessage;

  bool get available => firebaseReady;
  User? get user => firebaseReady ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => user != null;
  String get displayName => user?.displayName?.trim().isNotEmpty == true
      ? user!.displayName!.trim()
      : (user?.email ?? 'Kelime Fatihi');
  String get email => user?.email ?? '';

  Future<void> initialize() async {
    if (!firebaseReady) return;
    // Firebase Auth cihazda oturumu önbelleğe alır. Burada ağ beklemeden mevcut
    // kullanıcı durumunu okuyabiliyoruz; oyun offline açılışını bloke etmez.
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    if (!firebaseReady) {
      return 'Firebase henüz yapılandırılmadı. Yayın rehberindeki Firebase adımlarını tamamla.';
    }
    try {
      await _ensureGoogleInitialized();
      final account = await GoogleSignIn.instance.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null || idToken.isEmpty) {
        return 'Google kimlik doğrulama belirteci alınamadı.';
      }
      final credential = GoogleAuthProvider.credential(idToken: idToken);
      await FirebaseAuth.instance.signInWithCredential(credential);
      errorMessage = null;
      notifyListeners();
      return null;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      errorMessage = 'Google ile giriş başarısız: ${e.description ?? e.code.name}';
      notifyListeners();
      return errorMessage;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyFirebaseError(e);
      notifyListeners();
      return errorMessage;
    } catch (_) {
      errorMessage = 'Google ile giriş tamamlanamadı. İnternet ve Firebase ayarlarını kontrol et.';
      notifyListeners();
      return errorMessage;
    }
  }

  Future<String?> signInWithApple() async {
    if (!firebaseReady) {
      return 'Firebase henüz yapılandırılmadı. Yayın rehberindeki Firebase adımlarını tamamla.';
    }
    try {
      final provider = AppleAuthProvider()
        ..addScope('email')
        ..addScope('name');
      await FirebaseAuth.instance.signInWithProvider(provider);
      errorMessage = null;
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyFirebaseError(e);
      notifyListeners();
      return errorMessage;
    } catch (_) {
      errorMessage = 'Apple ile giriş tamamlanamadı. Apple/Firebase yapılandırmasını kontrol et.';
      notifyListeners();
      return errorMessage;
    }
  }

  Future<void> signOut() async {
    if (!firebaseReady) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Kullanıcı Apple ile giriş yaptıysa Google oturumu olmayabilir.
    }
    await FirebaseAuth.instance.signOut();
    notifyListeners();
  }

  Future<Map<String, dynamic>?> loadProgress() async {
    final current = user;
    if (current == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('players')
          .doc(current.uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      return snapshot.data();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProgress(Map<String, dynamic> progress) async {
    final current = user;
    if (current == null) return;
    try {
      await FirebaseFirestore.instance.collection('players').doc(current.uid).set(
        <String, dynamic>{
          ...progress,
          'uid': current.uid,
          'email': current.email,
          'displayName': current.displayName,
          'updatedAt': FieldValue.serverTimestamp(),
          'schemaVersion': 1,
        },
        SetOptions(merge: true),
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline durumda oyun yerel kayıtta devam eder. Firestore mobil SDK kendi
      // önbelleğini kullanır; sonraki senkron denemesinde tekrar gönderilir.
    }
  }

  Future<String?> deleteAccount() async {
    final current = user;
    if (current == null) return null;
    try {
      // Apple, Sign in with Apple kullanan uygulamalarda hesap silinirken
      // yetkilendirme token'ının da iptal edilmesini ister. Firebase bu işlem
      // için yeni bir Apple authorization code ile revoke API'si sunar.
      final usesApple = current.providerData.any((p) => p.providerId == 'apple.com');
      if (usesApple && Platform.isIOS) {
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        final credential = await FirebaseAuth.instance.signInWithProvider(provider);
        final authCode = credential.additionalUserInfo?.authorizationCode;
        if (authCode != null && authCode.isNotEmpty) {
          await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(authCode);
        }
      }

      await FirebaseFirestore.instance.collection('players').doc(current.uid).delete();
      await FirebaseAuth.instance.currentUser?.delete();
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return 'Güvenlik nedeniyle hesabı silmeden önce yeniden giriş yapmalısın.';
      }
      return _friendlyFirebaseError(e);
    } catch (_) {
      return 'Hesap silinemedi. İnternet bağlantını kontrol edip tekrar dene.';
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize();
    _googleInitialized = true;
  }

  String _friendlyFirebaseError(FirebaseAuthException e) {
    return switch (e.code) {
      'network-request-failed' => 'İnternet bağlantısı kurulamadı.',
      'account-exists-with-different-credential' =>
        'Bu e-posta başka bir giriş yöntemiyle zaten kayıtlı.',
      'credential-already-in-use' => 'Bu hesap başka bir kullanıcıya bağlı.',
      'user-disabled' => 'Bu kullanıcı hesabı devre dışı.',
      _ => e.message ?? 'Kimlik doğrulama işlemi başarısız oldu.',
    };
  }
}
