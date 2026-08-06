import 'package:flutter_test/flutter_test.dart';
import 'package:kelime_fatihi/models/competition.dart';

void main() {
  test('hafta pazartesi anahtarıyla başlar', () {
    expect(CompetitionPeriod.weekKey(DateTime(2026, 8, 3)), '2026-08-03');
    expect(CompetitionPeriod.weekKey(DateTime(2026, 8, 6)), '2026-08-03');
    expect(CompetitionPeriod.weekKey(DateTime(2026, 8, 9)), '2026-08-03');
    expect(CompetitionPeriod.weekKey(DateTime(2026, 8, 10)), '2026-08-10');
  });

  test('sezon ay bazında sıfırlanır', () {
    expect(CompetitionPeriod.seasonKey(DateTime(2026, 8, 31)), '2026-08');
    expect(CompetitionPeriod.seasonKey(DateTime(2026, 9, 1)), '2026-09');
  });

  test('lig puanı formülü sabittir', () {
    expect(
      CompetitionScoring.levelCompletion(bonusWords: 3, perfect: true),
      180,
    );
    expect(
      CompetitionScoring.levelCompletion(bonusWords: 0, perfect: false),
      100,
    );
    expect(CompetitionScoring.dailyWin, 75);
  });

  test('sezon lig eşikleri doğru çalışır', () {
    expect(LeagueTier.forScore(0), LeagueTier.bronze);
    expect(LeagueTier.forScore(2999), LeagueTier.bronze);
    expect(LeagueTier.forScore(3000), LeagueTier.silver);
    expect(LeagueTier.forScore(8000), LeagueTier.gold);
    expect(LeagueTier.forScore(15000), LeagueTier.diamond);
    expect(LeagueTier.forScore(25000), LeagueTier.conqueror);
  });


  test('Fatih adı Türkçe büyük-küçük harfe göre tekil normalize edilir', () {
    expect(UsernameRules.normalize('AlpFatih'), 'alpfatih');
    expect(UsernameRules.normalize('ALP FATİH'), 'alp_fatih');
    expect(UsernameRules.normalize('Alp_Fatih'), 'alp_fatih');
    expect(UsernameRules.normalize('IŞIK'), 'ışık');
    expect(UsernameRules.normalize('İPEK'), 'ipek');
  });

  test('Fatih adı yalnız güvenli 3-18 karakter biçimini kabul eder', () {
    expect(UsernameRules.validate('AlpFatih'), isNull);
    expect(UsernameRules.validate('Çağrı 34'), isNull);
    expect(UsernameRules.validate('ab'), isNotNull);
    expect(UsernameRules.validate('alp@mail'), isNotNull);
    expect(UsernameRules.validate('alp/fatih'), isNotNull);
    expect(UsernameRules.validate('_alpfatih'), isNotNull);
    expect(UsernameRules.validate('12345'), isNotNull);
  });

  test('Fatih adı yönetici taklidi ve açık uygunsuz adları reddeder', () {
    expect(UsernameRules.validate('admin'), isNotNull);
    expect(UsernameRules.validate('admin123'), isNotNull);
    expect(UsernameRules.validate('Kelime Fatihi'), isNotNull);
    expect(UsernameRules.validate('porno123'), isNotNull);
    expect(UsernameRules.validate('seks_kralı'), isNotNull);
    // Kısa yasak parçalar substring olarak kullanılmadığı için masum sözcük
    // yanlış pozitif üretmez.
    expect(UsernameRules.validate('Musiki'), isNull);
  });

  test('moderasyon rapor nedenleri sabit backend anahtarlarına sahiptir', () {
    expect(
      ModerationReportReason.inappropriateUsername.key,
      'inappropriate_username',
    );
    expect(ModerationReportReason.impersonation.key, 'impersonation');
    expect(ModerationReportReason.other.key, 'other');
    expect(ModerationReportReason.values.length, 3);
  });

}
