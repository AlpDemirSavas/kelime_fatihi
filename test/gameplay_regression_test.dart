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
      purchases: PurchaseService(),
      audio: AudioService(),
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
      purchases: PurchaseService(),
      audio: AudioService(),
      account: AccountService(firebaseReady: false),
    );

    controller.currentLevel = dictionary.buildLevel(1);
    controller.hearts = 5;

    expect(dictionary.isProperName('ahmet'), isTrue);
    expect(dictionary.isProperName('merve'), isTrue);
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
      purchases: PurchaseService(),
      audio: AudioService(),
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
      purchases: PurchaseService(),
      audio: AudioService(),
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
      purchases: PurchaseService(),
      audio: AudioService(),
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
}
