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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
