import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/competition.dart';

class _UsernameTakenException implements Exception {
  const _UsernameTakenException();
}

class AccountService extends ChangeNotifier {
  AccountService({required this.firebaseReady});

  final bool firebaseReady;
  bool _googleInitialized = false;
  String? errorMessage;

  bool get available => firebaseReady;
  User? get user => firebaseReady ? FirebaseAuth.instance.currentUser : null;
  bool get signedIn => user != null;
  String get uid => user?.uid ?? '';
  String get displayName => user?.displayName?.trim().isNotEmpty == true
      ? user!.displayName!.trim()
      : (user?.email ?? 'Kelime Fatihi');
  String get email => user?.email ?? '';
  String get suggestedSocialUsername {
    final value = user?.displayName?.trim() ?? '';
    if (value.isEmpty) return '';
    final candidate = UsernameRules.sanitizeDisplay(value);
    return UsernameRules.validate(candidate) == null ? candidate : '';
  }

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
      errorMessage =
          'Google ile giriş başarısız: ${e.description ?? e.code.name}';
      notifyListeners();
      return errorMessage;
    } on FirebaseAuthException catch (e) {
      errorMessage = _friendlyFirebaseError(e);
      notifyListeners();
      return errorMessage;
    } catch (_) {
      errorMessage =
          'Google ile giriş tamamlanamadı. İnternet ve Firebase ayarlarını kontrol et.';
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
      errorMessage =
          'Apple ile giriş tamamlanamadı. Apple/Firebase yapılandırmasını kontrol et.';
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
      await FirebaseFirestore.instance
          .collection('players')
          .doc(current.uid)
          .set(<String, dynamic>{
            ...progress,
            'uid': current.uid,
            'email': current.email,
            'displayName': current.displayName,
            'updatedAt': FieldValue.serverTimestamp(),
            'schemaVersion': 1,
          }, SetOptions(merge: true))
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // Offline durumda oyun yerel kayıtta devam eder. Firestore mobil SDK kendi
      // önbelleğini kullanır; sonraki senkron denemesinde tekrar gönderilir.
    }
  }

  Future<String?> loadSocialUsername() async {
    final current = user;
    if (current == null) return null;
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('username_owners')
          .doc(current.uid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      final value = snapshot.data()?['displayName'] as String?;
      final cleaned = UsernameRules.sanitizeDisplay(value ?? '');
      return cleaned.isEmpty ? null : cleaned;
    } catch (_) {
      return null;
    }
  }

  Future<UsernameClaimResult> ensureSocialUsername({
    String? requestedUsername,
  }) async {
    final current = user;
    if (current == null) {
      return const UsernameClaimResult(
        error: 'Fatih adı seçmek için hesabınla giriş yapmalısın.',
      );
    }

    final existing = await loadSocialUsername();
    if (existing != null && existing.isNotEmpty) {
      return UsernameClaimResult(username: existing);
    }

    final requested = UsernameRules.sanitizeDisplay(requestedUsername ?? '');
    final validationError = UsernameRules.validate(requested);
    if (validationError != null) {
      return UsernameClaimResult(error: validationError);
    }

    final normalized = UsernameRules.normalize(requested);
    final db = FirebaseFirestore.instance;
    final usernameRef = db.collection('usernames').doc(normalized);
    final ownerRef = db.collection('username_owners').doc(current.uid);

    try {
      final claimedName = await db
          .runTransaction<String>((transaction) async {
            // Aynı hesap farklı cihazdan eşzamanlı katılırsa ilk başarılı
            // rezervasyon kazanır; kullanıcıdan ikinci kez ad istenmez.
            final ownerSnapshot = await transaction.get(ownerRef);
            final ownerData = ownerSnapshot.data();
            final ownerName = UsernameRules.sanitizeDisplay(
              ownerData?['displayName'] as String? ?? '',
            );
            if (ownerName.isNotEmpty) return ownerName;

            final usernameSnapshot = await transaction.get(usernameRef);
            if (usernameSnapshot.exists) {
              final reservedUid = usernameSnapshot.data()?['uid'] as String?;
              if (reservedUid != current.uid) {
                throw const _UsernameTakenException();
              }
            } else {
              transaction.set(usernameRef, <String, dynamic>{
                'uid': current.uid,
                'displayName': requested,
                'normalized': normalized,
                'createdAt': FieldValue.serverTimestamp(),
              });
            }

            transaction.set(ownerRef, <String, dynamic>{
              'uid': current.uid,
              'displayName': requested,
              'normalized': normalized,
              'createdAt': FieldValue.serverTimestamp(),
            });
            return requested;
          })
          .timeout(const Duration(seconds: 7));
      return UsernameClaimResult(username: claimedName);
    } on _UsernameTakenException {
      return const UsernameClaimResult(
        error: 'Bu Fatih adı daha önce alınmış. Başka bir ad seç.',
      );
    } catch (_) {
      return const UsernameClaimResult(
        error: 'Fatih adı doğrulanamadı. İnternet bağlantını kontrol edip tekrar dene.',
      );
    }
  }

  Future<SocialSyncResult?> syncSocialProfile({
    required int weeklyScore,
    required int seasonScore,
    required String weekKey,
    required String seasonKey,
    required int levelNumber,
    required int perfectConquests,
  }) async {
    final current = user;
    if (current == null) return null;

    try {
      final friendCode = await _ensureFriendCode(current.uid);
      var mergedWeekly = weeklyScore;
      var mergedSeason = seasonScore;
      final profileRef = FirebaseFirestore.instance
          .collection('social_profiles')
          .doc(current.uid);
      final publicName = await loadSocialUsername();
      if (publicName == null || publicName.isEmpty) return null;
      final usernameNormalized = UsernameRules.normalize(publicName);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(profileRef);
        final data = snapshot.data() ?? const <String, dynamic>{};
        final oldWeekKey = data['weekKey'] as String? ?? '';
        final oldSeasonKey = data['seasonKey'] as String? ?? '';
        final oldWeeklyScore = (data['weeklyScore'] as num?)?.toInt() ?? 0;
        final oldSeasonScore = (data['seasonScore'] as num?)?.toInt() ?? 0;

        mergedWeekly = oldWeekKey == weekKey
            ? max(oldWeeklyScore, weeklyScore)
            : weeklyScore;
        mergedSeason = oldSeasonKey == seasonKey
            ? max(oldSeasonScore, seasonScore)
            : seasonScore;

        transaction.set(profileRef, <String, dynamic>{
          'uid': current.uid,
          'displayName': publicName,
          'usernameNormalized': usernameNormalized,
          'friendCode': friendCode,
          'weekKey': weekKey,
          'weeklyScore': mergedWeekly,
          'seasonKey': seasonKey,
          'seasonScore': mergedSeason,
          'levelNumber': levelNumber,
          'perfectConquests': perfectConquests,
          'updatedAt': FieldValue.serverTimestamp(),
          'socialSchemaVersion': 2,
        }, SetOptions(merge: true));
      }).timeout(const Duration(seconds: 6));
      return SocialSyncResult(
        friendCode: friendCode,
        weeklyScore: mergedWeekly,
        seasonScore: mergedSeason,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Set<String>> loadBlockedUserIds() async {
    final current = user;
    if (current == null) return const <String>{};
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(current.uid)
          .collection('members')
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      return snapshot.docs.map((doc) => doc.id).toSet();
    } catch (_) {
      return const <String>{};
    }
  }

  Future<List<BlockedPlayer>> loadBlockedPlayers() async {
    final current = user;
    if (current == null) return const <BlockedPlayer>[];
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(current.uid)
          .collection('members')
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      return snapshot.docs
          .map((doc) => BlockedPlayer.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      // createdAt için index gerekmemesi adına ikinci, sırasız okuma yolu.
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('blocked_users')
            .doc(current.uid)
            .collection('members')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5));
        return snapshot.docs
            .map((doc) => BlockedPlayer.fromMap(doc.id, doc.data()))
            .toList();
      } catch (_) {
        return const <BlockedPlayer>[];
      }
    }
  }

  Future<List<LeaderboardEntry>> loadWeeklyLeaderboard(String weekKey) async {
    if (!signedIn) return const <LeaderboardEntry>[];
    try {
      final blocked = await loadBlockedUserIds();
      final snapshot = await FirebaseFirestore.instance
          .collection('social_profiles')
          .where('weekKey', isEqualTo: weekKey)
          .orderBy('weeklyScore', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 6));
      return snapshot.docs
          .where((doc) => !blocked.contains(doc.id))
          .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return const <LeaderboardEntry>[];
    }
  }

  Future<List<LeaderboardEntry>> loadSeasonLeaderboard(
    String seasonKey,
  ) async {
    if (!signedIn) return const <LeaderboardEntry>[];
    try {
      final blocked = await loadBlockedUserIds();
      final snapshot = await FirebaseFirestore.instance
          .collection('social_profiles')
          .where('seasonKey', isEqualTo: seasonKey)
          .orderBy('seasonScore', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 6));
      return snapshot.docs
          .where((doc) => !blocked.contains(doc.id))
          .map((doc) => LeaderboardEntry.fromMap(doc.id, doc.data()))
          .toList();
    } catch (_) {
      return const <LeaderboardEntry>[];
    }
  }

  Future<List<LeaderboardEntry>> loadFriendLeaderboard(String weekKey) async {
    final current = user;
    if (current == null) return const <LeaderboardEntry>[];
    try {
      final blocked = await loadBlockedUserIds();
      final friends = await FirebaseFirestore.instance
          .collection('friendships')
          .doc(current.uid)
          .collection('members')
          .limit(30)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 6));

      final ids = <String>{
        current.uid,
        ...friends.docs
            .map((doc) => doc.id)
            .where((uid) => !blocked.contains(uid)),
      };
      final entries = await Future.wait(
        ids.map((uid) async {
          try {
            final profile = await FirebaseFirestore.instance
                .collection('social_profiles')
                .doc(uid)
                .get(const GetOptions(source: Source.serverAndCache))
                .timeout(const Duration(seconds: 4));
            final data = profile.data();
            if (data == null || (data['weekKey'] as String? ?? '') != weekKey) {
              return null;
            }
            return LeaderboardEntry.fromMap(profile.id, data);
          } catch (_) {
            return null;
          }
        }),
      );
      final result = entries.whereType<LeaderboardEntry>().toList()
        ..sort((a, b) => b.weeklyScore.compareTo(a.weeklyScore));
      return result;
    } catch (_) {
      return const <LeaderboardEntry>[];
    }
  }

  Future<String?> reportUser({
    required String reportedUid,
    required String reportedDisplayName,
    required ModerationReportReason reason,
  }) async {
    final current = user;
    if (current == null) {
      return 'Şikâyet göndermek için hesabınla giriş yapmalısın.';
    }
    if (reportedUid.isEmpty || reportedUid == current.uid) {
      return 'Bu oyuncu şikâyet edilemez.';
    }

    final reportRef = FirebaseFirestore.instance
        .collection('user_reports')
        .doc(current.uid)
        .collection('reported')
        .doc(reportedUid);
    try {
      final existing = await reportRef
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));
      if (existing.exists) {
        return 'Bu oyuncuyu daha önce şikâyet ettin.';
      }
      await reportRef.set(<String, dynamic>{
        'reporterUid': current.uid,
        'reportedUid': reportedUid,
        'reportedDisplayName': reportedDisplayName.trim(),
        'reason': reason.key,
        'createdAt': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 5));
      return null;
    } catch (_) {
      return 'Şikâyet gönderilemedi. İnternet bağlantını kontrol edip tekrar dene.';
    }
  }

  Future<String?> blockUser({
    required String blockedUid,
    required String blockedDisplayName,
  }) async {
    final current = user;
    if (current == null) {
      return 'Oyuncu engellemek için hesabınla giriş yapmalısın.';
    }
    if (blockedUid.isEmpty || blockedUid == current.uid) {
      return 'Bu oyuncu engellenemez.';
    }

    try {
      final db = FirebaseFirestore.instance;
      final batch = db.batch();
      final blockRef = db
          .collection('blocked_users')
          .doc(current.uid)
          .collection('members')
          .doc(blockedUid);
      batch.set(blockRef, <String, dynamic>{
        'blockedUid': blockedUid,
        'displayName': blockedDisplayName.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      // Engellenen oyuncu kendi arkadaş listemizden de çıkarılır.
      batch.delete(
        db
            .collection('friendships')
            .doc(current.uid)
            .collection('members')
            .doc(blockedUid),
      );
      await batch.commit().timeout(const Duration(seconds: 5));
      return null;
    } catch (_) {
      return 'Oyuncu engellenemedi. İnternet bağlantını kontrol edip tekrar dene.';
    }
  }

  Future<void> unblockUser(String blockedUid) async {
    final current = user;
    if (current == null || blockedUid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('blocked_users')
          .doc(current.uid)
          .collection('members')
          .doc(blockedUid)
          .delete()
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<String?> addFriendByCode(String rawCode) async {
    final current = user;
    if (current == null) return 'Arkadaş eklemek için hesabınla giriş yapmalısın.';
    final code = rawCode.trim().toUpperCase().replaceAll(' ', '');
    if (code.isEmpty) return 'Arkadaş kodunu yaz.';

    try {
      final db = FirebaseFirestore.instance;
      final codeDoc = await db
          .collection('friend_codes')
          .doc(code)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      final friendUid = codeDoc.data()?['uid'] as String?;
      if (friendUid == null || friendUid.isEmpty) {
        return 'Bu arkadaş kodu bulunamadı.';
      }
      if (friendUid == current.uid) return 'Kendi arkadaş kodunu ekleyemezsin.';

      final block = await db
          .collection('blocked_users')
          .doc(current.uid)
          .collection('members')
          .doc(friendUid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));
      if (block.exists) {
        return 'Bu oyuncu engellenmiş. Önce engeli kaldırmalısın.';
      }

      final profile = await db
          .collection('social_profiles')
          .doc(friendUid)
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 5));
      if (!profile.exists) return 'Bu oyuncu sosyal sıralamaya katılmamış.';

      await db
          .collection('friendships')
          .doc(current.uid)
          .collection('members')
          .doc(friendUid)
          .set(<String, dynamic>{
            'friendUid': friendUid,
            'createdAt': FieldValue.serverTimestamp(),
          })
          .timeout(const Duration(seconds: 5));
      return null;
    } catch (_) {
      return 'Arkadaş eklenemedi. İnternet bağlantını kontrol edip tekrar dene.';
    }
  }

  Future<void> removeFriend(String friendUid) async {
    final current = user;
    if (current == null || friendUid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('friendships')
          .doc(current.uid)
          .collection('members')
          .doc(friendUid)
          .delete()
          .timeout(const Duration(seconds: 5));
    } catch (_) {}
  }

  Future<String?> leaveSocialCompetition() async {
    final current = user;
    if (current == null) return null;
    final deleted = await _deleteSocialData(current.uid, deleteUsername: false);
    return deleted
        ? null
        : 'Lig profili silinemedi. İnternet bağlantını kontrol edip tekrar dene.';
  }

  Future<String?> deleteAccount() async {
    final current = user;
    if (current == null) return null;
    try {
      final socialDeleted = await _deleteSocialData(current.uid, deleteUsername: true);
      if (!socialDeleted) {
        return 'Sosyal lig verileri silinemedi. İnternet bağlantını kontrol edip tekrar dene.';
      }

      // Apple, Sign in with Apple kullanan uygulamalarda hesap silinirken
      // yetkilendirme token'ının da iptal edilmesini ister. Firebase bu işlem
      // için yeni bir Apple authorization code ile revoke API'si sunar.
      final usesApple = current.providerData.any(
        (p) => p.providerId == 'apple.com',
      );
      if (usesApple && Platform.isIOS) {
        final provider = AppleAuthProvider()
          ..addScope('email')
          ..addScope('name');
        final credential = await FirebaseAuth.instance.signInWithProvider(
          provider,
        );
        final authCode = credential.additionalUserInfo?.authorizationCode;
        if (authCode != null && authCode.isNotEmpty) {
          await FirebaseAuth.instance.revokeTokenWithAuthorizationCode(
            authCode,
          );
        }
      }

      await FirebaseFirestore.instance
          .collection('players')
          .doc(current.uid)
          .delete();
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

  Future<String> _ensureFriendCode(String uid) async {
    final profileRef = FirebaseFirestore.instance
        .collection('social_profiles')
        .doc(uid);
    try {
      final profile = await profileRef
          .get(const GetOptions(source: Source.serverAndCache))
          .timeout(const Duration(seconds: 4));
      final existing = profile.data()?['friendCode'] as String?;
      if (existing != null && existing.isNotEmpty) return existing;
    } catch (_) {}

    for (var salt = 0; salt < 8; salt++) {
      final code = _friendCodeFor(uid, salt);
      final codeRef = FirebaseFirestore.instance.collection('friend_codes').doc(code);
      try {
        final claimed = await FirebaseFirestore.instance
            .runTransaction<bool>((transaction) async {
              final snapshot = await transaction.get(codeRef);
              if (snapshot.exists) {
                return snapshot.data()?['uid'] == uid;
              }
              transaction.set(codeRef, <String, dynamic>{
                'uid': uid,
                'createdAt': FieldValue.serverTimestamp(),
              });
              return true;
            })
            .timeout(const Duration(seconds: 5));
        if (claimed) return code;
      } catch (_) {}
    }
    throw StateError('Arkadaş kodu oluşturulamadı.');
  }

  String _friendCodeFor(String uid, int salt) {
    const offset = 1469598103934665603;
    const prime = 1099511628211;
    const mask = 0x7FFFFFFFFFFFFFFF;
    var hash = offset;
    for (final unit in '$uid:$salt'.codeUnits) {
      hash ^= unit;
      hash = (hash * prime) & mask;
    }
    final raw = hash.toRadixString(36).toUpperCase().padLeft(10, '0');
    return 'KF-${raw.substring(raw.length - 8)}';
  }

  Future<bool> _deleteSocialData(
    String uid, {
    required bool deleteUsername,
  }) async {
    try {
      final db = FirebaseFirestore.instance;
      final profileRef = db.collection('social_profiles').doc(uid);
      final ownerRef = db.collection('username_owners').doc(uid);
      final results = await Future.wait([
        profileRef
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 4)),
        ownerRef
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 4)),
        db
            .collection('friendships')
            .doc(uid)
            .collection('members')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5)),
      ]);
      final profile = results[0] as DocumentSnapshot<Map<String, dynamic>>;
      final owner = results[1] as DocumentSnapshot<Map<String, dynamic>>;
      final members = results[2] as QuerySnapshot<Map<String, dynamic>>;
      final friendCode = profile.data()?['friendCode'] as String?;
      final normalized = owner.data()?['normalized'] as String?;
      final friendCodesToDelete = <String>{};
      if (friendCode != null && friendCode.isNotEmpty) {
        friendCodesToDelete.add(friendCode);
      } else if (deleteUsername && owner.exists) {
        // Profil yazılmadan önce bağlantı kopmuş olsa bile hesap silme,
        // deterministic olarak ayrılmış olabilecek arkadaş kodunu geride bırakmaz.
        final candidates = List<String>.generate(
          8,
          (salt) => _friendCodeFor(uid, salt),
        );
        final snapshots = await Future.wait(
          candidates.map((candidate) async {
            try {
              return await db
                  .collection('friend_codes')
                  .doc(candidate)
                  .get(const GetOptions(source: Source.serverAndCache))
                  .timeout(const Duration(seconds: 2));
            } catch (_) {
              return null;
            }
          }),
        );
        for (var index = 0; index < snapshots.length; index++) {
          if (snapshots[index]?.data()?['uid'] == uid) {
            friendCodesToDelete.add(candidates[index]);
          }
        }
      }

      final batch = db.batch();
      for (final doc in members.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(profileRef);
      for (final code in friendCodesToDelete) {
        batch.delete(db.collection('friend_codes').doc(code));
      }

      // Ligden çıkmak kullanıcı adını serbest bırakmaz. Böylece oyuncu aynı
      // hesapla geri geldiğinde ikinci kez ad seçmez ve başka biri adı alamaz.
      // Tam hesap silmede ise rezervasyon da kaldırılır.
      if (deleteUsername && normalized != null && normalized.isNotEmpty) {
        batch.delete(db.collection('usernames').doc(normalized));
        batch.delete(ownerRef);
      }
      await batch.commit().timeout(const Duration(seconds: 6));
      if (deleteUsername) {
        final moderationDeleted = await _deleteOwnModerationData(uid);
        if (!moderationDeleted) return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> _deleteOwnModerationData(String uid) async {
    try {
      final db = FirebaseFirestore.instance;
      final results = await Future.wait([
        db
            .collection('blocked_users')
            .doc(uid)
            .collection('members')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5)),
        db
            .collection('user_reports')
            .doc(uid)
            .collection('reported')
            .get(const GetOptions(source: Source.serverAndCache))
            .timeout(const Duration(seconds: 5)),
      ]);
      final blocked = results[0];
      final reports = results[1];
      if (blocked.docs.isEmpty && reports.docs.isEmpty) return true;

      final batch = db.batch();
      for (final doc in blocked.docs) {
        batch.delete(doc.reference);
      }
      for (final doc in reports.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(const Duration(seconds: 6));
      return true;
    } catch (_) {
      return false;
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
