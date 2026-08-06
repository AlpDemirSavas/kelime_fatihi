import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_fatihi/controllers/game_controller.dart';
import 'package:kelime_fatihi/services/account_service.dart';
import 'package:kelime_fatihi/services/ad_service.dart';
import 'package:kelime_fatihi/services/audio_service.dart';
import 'package:kelime_fatihi/services/dictionary_service.dart';
import 'package:kelime_fatihi/services/purchase_service.dart';
import 'package:kelime_fatihi/services/storage_service.dart';
import 'package:kelime_fatihi/widgets/letter_wheel.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _TestPurchaseService implements PurchaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Unit/regression tests do not exercise the native store. Return completed
    // futures for the lazy billing entry points if a test reaches them, and
    // otherwise keep the service as a harmless no-op test double.
    if (invocation.memberName == #initialize ||
        invocation.memberName == #restore) {
      return Future<void>.value();
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  test('0 can ile doğru hedef kelime bile kabul edilmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.hearts = 0;

    final result = await controller.submitConquestWord(
      controller.currentLevel.words.first,
    );

    expect(result.noHearts, isTrue);
    expect(result.isTarget, isFalse);
    expect(controller.foundWords, isEmpty);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });


  test('yaygın özel isim bonus olur ve can eksiltmez', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.hearts = 5;

    expect(dictionary.isProperName('ahmet'), isTrue);
    expect(dictionary.isProperName('merve'), isTrue);
    expect(dictionary.isProperName('aras'), isTrue);
    expect(dictionary.isProperName('asya'), isTrue);
    expect(dictionary.isProperName('alya'), isTrue);
    expect(dictionary.isProperName('fas'), isTrue);
    expect(dictionary.isProperName('kayı'), isTrue);
    expect(dictionary.isProperName('kuran'), isTrue);
    expect(dictionary.contains('ahmet'), isFalse);

    final result = await controller.submitConquestWord('ahmet');

    expect(result.isBonus, isTrue);
    expect(result.lostHeart, isFalse);
    expect(controller.hearts, 5);
    expect(controller.bonusWords, contains('ahmet'));

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('reddedilen son kelime tutulur ve geçerli kelimede temizlenir', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.hearts = 5;

    await controller.submitConquestWord('xyz');
    expect(controller.lastRejectedWord, 'xyz');

    await controller.submitConquestWord(controller.currentLevel.words.first);
    expect(controller.lastRejectedWord, isEmpty);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('10. bölüm kilometre taşı ödülünü yalnız bir kez üretir', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.levelNumber = 10;
    controller.levelsCompleted = 9;
    controller.currentLevel = dictionary.buildLevel(10);
    controller.foundWords.addAll(controller.currentLevel.words);
    final coinsBefore = controller.coins;

    await controller.completeLevel();
    final reward = controller.takePendingMilestoneReward();

    expect(controller.isMilestoneLevel(10), isTrue);
    expect(reward, isNotNull);
    expect(reward!.level, 10);
    expect(reward.coins, 10);
    expect(controller.coins, greaterThanOrEqualTo(coinsBefore + 15));
    expect(controller.takePendingMilestoneReward(), isNull);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('günün kelimesi kazanılınca günlük seri ve rekor artar', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.dailyDateKey = '2099-12-31';
    controller.dailyWord = dictionary.dailyWord(DateTime(2099, 12, 31));
    final error = await controller.submitDaily(controller.dailyWord);

    expect(error, isNull);
    expect(controller.dailyFinished, isTrue);
    expect(controller.dailyWon, isTrue);
    expect(controller.dailyPuzzleStreak, 1);
    expect(controller.bestDailyPuzzleStreak, greaterThanOrEqualTo(1));

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('gün değişince günlük kelime durumu uygulamayı kapatmadan yenilenir', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();
    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.dailyDateKey = '2000-01-01';
    controller.dailyWord = 'kalem';
    controller.dailyGuesses = <String>['kalem'];
    controller.dailyFinished = true;
    controller.dailyWon = true;
    await storage.setString('daily_date', '2000-01-01');
    await storage.setStringList('daily_guesses', const <String>['kalem']);
    await storage.setBool('daily_finished', true);
    await storage.setBool('daily_won', true);

    final refreshed = await controller.refreshDailyStateIfNeeded();

    expect(refreshed, isTrue);
    expect(controller.dailyDateKey, isNot('2000-01-01'));
    expect(controller.dailyWord, dictionary.dailyWord(DateTime.now()));
    expect(controller.dailyGuesses, isEmpty);
    expect(controller.dailyFinished, isFalse);
    expect(controller.dailyWon, isFalse);
    expect(await controller.refreshDailyStateIfNeeded(), isFalse);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  testWidgets('harf tekerinde geri sürükleme son seçimleri geri alır', (
    tester,
  ) async {
    String? submitted;
    const letters = ['k', 'r', 'e', 'd', 'i'];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 310,
              height: 310,
              child: LetterWheel(
                letters: letters,
                onSubmitted: (word) => submitted = word,
              ),
            ),
          ),
        ),
      ),
    );

    final box = tester.renderObject<RenderBox>(find.byType(LetterWheel));
    const size = 310.0;
    final center = const Offset(size / 2, size / 2);
    final radius = size * .34;
    Offset node(int index) {
      final angle = -pi / 2 + index * 2 * pi / letters.length;
      return box.localToGlobal(
        center + Offset(cos(angle), sin(angle)) * radius,
      );
    }

    final gesture = await tester.startGesture(node(0)); // k
    await gesture.moveTo(node(1)); // kr
    await gesture.moveTo(node(2)); // kre (yanlış seçim)
    await gesture.moveTo(node(1)); // kr -> e geri al
    await gesture.moveTo(node(0)); // k  -> r geri al
    await gesture.moveTo(node(2)); // ke
    await gesture.moveTo(node(3)); // ked
    await gesture.moveTo(node(4)); // kedi
    await gesture.up();
    await tester.pump();

    expect(submitted, 'kedi');
  });

  test('kusursuz fetih +5 altın verir ve sayacı artırır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.levelNumber = 1;
    controller.currentLevel = dictionary.buildLevel(1);
    controller.foundWords.addAll(controller.currentLevel.words);
    controller.hintUsedThisLevel = false;
    controller.mistakesThisLevel = 0;
    final coinsBefore = controller.coins;

    await controller.completeLevel();
    final perfect = controller.takePendingPerfectReward();

    expect(perfect, isNotNull);
    expect(perfect!.coins, 5);
    expect(controller.perfectConquests, 1);
    expect(controller.coins, greaterThanOrEqualTo(coinsBefore + 10));
    expect(controller.takePendingPerfectReward(), isNull);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('yanlış kelime kusursuz fetih hakkını kapatır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.levelNumber = 1;
    controller.currentLevel = dictionary.buildLevel(1);
    await controller.submitConquestWord('xyz');
    expect(controller.mistakesThisLevel, 1);
    controller.foundWords.addAll(controller.currentLevel.words);

    await controller.completeLevel();
    expect(controller.takePendingPerfectReward(), isNull);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('25. bonus kelime Bonus Hazinesini açar', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.hearts = 5;
    controller.bonusTreasureProgress = 24;
    final coinsBefore = controller.coins;

    final result = await controller.submitConquestWord('ahmet');

    expect(result.isBonus, isTrue);
    expect(result.bonusTreasureOpened, isTrue);
    expect(controller.bonusTreasureProgress, 0);
    expect(controller.bonusTreasuresOpened, 1);
    expect(controller.coins, coinsBefore + 21);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('bir harf aç ilk harften farklı bir konumu açar', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.coins = 200;

    final revealResult = await controller.useHint(ConquestHintType.revealLetter);

    expect(revealResult.used, isTrue);
    expect(revealResult.spentCoins, 25);
    expect(
      controller.hints.values.any((indexes) => indexes.contains(0)),
      isFalse,
      reason: 'Bir harf aç, ilk harfi açmamalı.',
    );
    expect(
      controller.hints.values.any((indexes) => indexes.any((i) => i > 0)),
      isTrue,
    );

    final firstLetterResult =
        await controller.useHint(ConquestHintType.firstLetter);

    expect(firstLetterResult.used, isTrue);
    expect(firstLetterResult.spentCoins, 20);
    expect(
      controller.hints.values.any((indexes) => indexes.contains(0)),
      isTrue,
    );

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('akıllı ipucu türleri doğru maliyetle harf açar', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final controller = GameController(
      dictionary: dictionary,
      storage: StorageService(),
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.coins = 200;
    final before = controller.coins;
    final result = await controller.useHint(ConquestHintType.firstLetter);

    expect(result.used, isTrue);
    expect(result.spentCoins, 20);
    expect(controller.coins, before - 20);
    expect(controller.hintUsedThisLevel, isTrue);
    expect(controller.hints.values.any((indexes) => indexes.contains(0)), isTrue);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });


  // Accessibility preferences are local UI preferences. They must not mutate
  // gameplay progress or campaign content.
  test('titreşim ve azaltılmış animasyon tercihleri kalıcı saklanır', () async {
    final storage = StorageService();
    final controller = GameController(
      dictionary: DictionaryService(),
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    await controller.setHapticsEnabled(false);
    await controller.setReduceMotionEnabled(true);

    expect(controller.hapticsEnabled, isFalse);
    expect(controller.reduceMotionEnabled, isTrue);
    expect(controller.effectiveReduceMotion, isTrue);
    expect(await storage.getBool('haptics_enabled', true), isFalse);
    expect(await storage.getBool('reduce_motion_enabled', false), isTrue);

    controller.setSystemReduceMotion(true);
    expect(controller.systemReduceMotion, isTrue);
    expect(controller.effectiveReduceMotion, isTrue);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('App Store v14 reklamda tamamlanan tahta migration öncesi kurtarılır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();

    // App Store v14'te 100-999 arası bölümlerde 6 zorunlu hedef vardı.
    // Reklam sırasında kill olursa altı hedef kaydedilmiş fakat level_number
    // ilerlememiş olabiliyordu.
    await storage.setInt('content_version', 14);
    await storage.setInt('level_number', 101);
    await storage.setInt('levels_completed', 100);
    await storage.setInt('coins', 120);
    await storage.setInt('active_level_number', 101);
    await storage.setStringList(
      'found_words',
      const <String>['a', 'b', 'c', 'd', 'e', 'f'],
    );
    await storage.setStringList('bonus_words', const <String>[]);
    await storage.setBool('hint_used_level', true);
    await storage.setString('hints_json', '{}');

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();

    expect(await storage.getInt('content_version', -1), 17);
    expect(controller.levelNumber, 102);
    expect(controller.levelsCompleted, 101);
    expect(controller.coins, 125);
    expect(controller.foundWords, isEmpty);
    expect(await storage.getInt('active_level_number', -1), 102);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('App Store v14 açık tahta v17 kampanyaya güvenli taşınır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();

    await storage.setInt('content_version', 14);
    await storage.setInt('level_number', 321);
    await storage.setInt('levels_completed', 320);
    await storage.setInt('coins', 777);
    await storage.setInt('hearts', 4);
    await storage.setInt('active_level_number', 321);
    await storage.setStringList('found_words', const <String>['eski']);
    await storage.setStringList('bonus_words', const <String>['tahta']);
    await storage.setBool('hint_used_level', true);
    await storage.setInt('mistakes_this_level', 3);
    await storage.setString('hints_json', '{"eski":[0]}');

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();

    expect(await storage.getInt('content_version', -1), 17);
    expect(controller.levelNumber, 321);
    expect(controller.levelsCompleted, 320);
    expect(controller.coins, 777);
    expect(controller.hearts, 4);
    expect(controller.foundWords, isEmpty);
    expect(controller.bonusWords, isEmpty);
    expect(controller.hints, isEmpty);
    expect(controller.hintUsedThisLevel, isFalse);
    expect(controller.mistakesThisLevel, 0);
    expect(await storage.getInt('active_level_number', -1), 321);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('v15 açık tahta v17 kalite kampanyasında güvenli sıfırlanır', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();

    await storage.setInt('content_version', 15);
    await storage.setInt('level_number', 777);
    await storage.setInt('levels_completed', 776);
    await storage.setInt('coins', 444);
    await storage.setInt('hearts', 3);
    await storage.setInt('active_level_number', 777);
    await storage.setStringList('found_words', const <String>['eski']);
    await storage.setStringList('bonus_words', const <String>['tahta']);
    await storage.setBool('hint_used_level', true);
    await storage.setInt('mistakes_this_level', 2);
    await storage.setString('hints_json', '{"eski":[0]}');

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();

    expect(await storage.getInt('content_version', -1), 17);
    expect(controller.levelNumber, 777);
    expect(controller.levelsCompleted, 776);
    expect(controller.coins, 444);
    expect(controller.hearts, 3);
    expect(controller.foundWords, isEmpty);
    expect(controller.bonusWords, isEmpty);
    expect(controller.hints, isEmpty);
    expect(controller.hintUsedThisLevel, isFalse);
    expect(controller.mistakesThisLevel, 0);
    expect(await storage.getInt('active_level_number', -1), 777);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('v17 bölüm lig puanı kalıcıdır ve yeniden açılışta iki kez yazılmaz', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();
    await storage.setInt('content_version', 17);

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();
    controller.foundWords.addAll(controller.currentLevel.words);
    controller.bonusWords.addAll(const <String>['bonus1', 'bonus2']);

    await controller.completeLevel();
    expect(controller.weeklyScore, 170);
    expect(controller.seasonScore, 170);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();

    final reopened = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await reopened.initialize();
    expect(reopened.weeklyScore, 170);
    expect(reopened.seasonScore, 170);

    reopened.ads.dispose();
    reopened.purchases.dispose();
    reopened.account.dispose();
    await reopened.audio.dispose();
    reopened.dispose();
  });

  test('v16 açık tahta v17 sosyal/UI güncellemesinde aynen korunur', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();
    final level = dictionary.buildLevel(321);
    final found = level.words.take(2).toList();

    await storage.setInt('content_version', 16);
    await storage.setInt('level_number', 321);
    await storage.setInt('levels_completed', 320);
    await storage.setInt('coins', 777);
    await storage.setInt('hearts', 4);
    await storage.setInt('active_level_number', 321);
    await storage.setStringList('found_words', found);
    await storage.setStringList('bonus_words', const <String>['bonus']);
    await storage.setBool('hint_used_level', true);
    await storage.setInt('mistakes_this_level', 2);
    await storage.setString('hints_json', '{}');

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();

    expect(await storage.getInt('content_version', -1), 17);
    expect(controller.levelNumber, 321);
    expect(controller.levelsCompleted, 320);
    expect(controller.coins, 777);
    expect(controller.hearts, 4);
    expect(controller.foundWords, containsAll(found));
    expect(controller.bonusWords, contains('bonus'));
    expect(controller.hintUsedThisLevel, isTrue);
    expect(controller.mistakesThisLevel, 2);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

  test('reklamda kapanmış eski tam tahta açılışta otomatik ilerler', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();
    final level = dictionary.buildLevel(1);

    // Eski hatanın bıraktığı durum: son kelime dahil tüm hedefler diskte,
    // fakat reklam sırasında uygulama kapanmış ve level_number ilerlememiş.
    await storage.setInt('content_version', 16);
    await storage.setInt('level_number', 1);
    await storage.setInt('levels_completed', 0);
    await storage.setInt('coins', 120);
    await storage.setInt('active_level_number', 1);
    await storage.setStringList('found_words', level.words);
    await storage.setStringList('bonus_words', const <String>[]);
    await storage.setBool('hint_used_level', false);
    await storage.setInt('mistakes_this_level', 0);
    await storage.setString('hints_json', '{}');

    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await controller.initialize();

    expect(controller.levelNumber, 2);
    expect(controller.levelsCompleted, 1);
    expect(controller.foundWords, isEmpty);
    // +5 bölüm, +5 Kusursuz Fetih. Recovery ödülü de kaybolmaz.
    expect(controller.coins, 130);

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();

    // Aynı kayıt ikinci kez açıldığında completion tekrar uygulanmamalı.
    final reopened = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );
    await reopened.initialize();

    expect(reopened.levelNumber, 2);
    expect(reopened.levelsCompleted, 1);
    expect(reopened.coins, 130);

    reopened.ads.dispose();
    reopened.purchases.dispose();
    reopened.account.dispose();
    await reopened.audio.dispose();
    reopened.dispose();
  });

  test('completeLevel ilerlemeyi reklamdan bağımsız kalıcı kaydeder', () async {
    final dictionary = DictionaryService();
    await dictionary.load();
    final storage = StorageService();
    final controller = GameController(
      dictionary: dictionary,
      storage: storage,
      ads: AdService(),
      purchases: _TestPurchaseService(),
      audio: AudioService(enabled: false),
      account: AccountService(firebaseReady: false),
    );

    controller.levelNumber = 1;
    controller.levelsCompleted = 0;
    controller.currentLevel = dictionary.buildLevel(1);
    controller.foundWords.addAll(controller.currentLevel.words);

    await controller.completeLevel();

    expect(await storage.getInt('level_number', -1), 2);
    expect(await storage.getInt('levels_completed', -1), 1);
    expect(await storage.getInt('active_level_number', -1), 2);
    expect(await storage.getStringList('found_words'), isEmpty);
    expect(await storage.getString('pending_level_completion_v1'), '');

    controller.ads.dispose();
    controller.purchases.dispose();
    controller.account.dispose();
    await controller.audio.dispose();
    controller.dispose();
  });

}
