import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../core/turkish_text.dart';
import '../models/chest_reward.dart';
import '../models/conquest_level.dart';
import '../models/conquest_region.dart';
import '../models/daily_mission.dart';
import '../models/word_feedback.dart';
import '../services/account_service.dart';
import '../services/ad_service.dart';
import '../services/audio_service.dart';
import '../services/dictionary_service.dart';
import '../services/purchase_service.dart';
import '../services/storage_service.dart';

class GameController extends ChangeNotifier {
  GameController({
    required this.dictionary,
    required this.storage,
    required this.ads,
    required this.purchases,
    required this.audio,
    required this.account,
  });

  final DictionaryService dictionary;
  final StorageService storage;
  final AdService ads;
  final PurchaseService purchases;
  final AudioService audio;
  final AccountService account;

  bool loading = true;
  int hearts = 5;
  int coins = 120;
  int levelNumber = 1;
  int levelsCompleted = 0;
  int totalWordsFound = 0;
  int dailyWins = 0;
  int dailyStreak = 0;
  int bestDailyStreak = 0;
  String streakRewardMessage = '';
  int lastHeartSyncMs = 0;
  int comboCount = 0;
  int bestCombo = 0;
  int freeHints = 0;
  int crownFragments = 0;
  bool soundEnabled = true;
  bool hintUsedThisLevel = false;
  bool isAdFree = false;
  bool cloudSyncing = false;
  String cloudStatusMessage = '';
  Timer? _cloudSyncTimer;
  Timer? _heartTicker;

  static const int maxNaturalHearts = 5;
  static const Duration heartRefill = Duration(minutes: 20);

  late ConquestLevel currentLevel;
  final Set<String> foundWords = <String>{};
  final Set<String> bonusWords = <String>{};
  final Map<String, Set<int>> hints = <String, Set<int>>{};

  List<String> dailyGuesses = <String>[];
  bool dailyFinished = false;
  bool dailyWon = false;
  String dailyDateKey = '';
  String dailyWord = 'kalem';

  List<DailyMission> dailyMissions = <DailyMission>[];

  bool get campaignCompleted => levelNumber > DictionaryService.maxLevel;
  int get displayLevel => min(levelNumber, DictionaryService.maxLevel);
  ConquestRegion get currentRegion => ConquestRegion.forLevel(displayLevel);
  int get crownsUnlocked => crownFragments ~/ 5;
  bool get signedIn => account.signedIn;
  String get accountName => account.displayName;
  String get accountEmail => account.email;
  List<String> get sortedBonusWords {
    final words = bonusWords.toList()..sort();
    return words;
  }

  Future<void> initialize() async {
    await dictionary.load();
    hearts = await storage.getInt('hearts', 5);
    coins = await storage.getInt('coins', 120);
    levelNumber = await storage.getInt('level_number', 1);
    levelsCompleted = await storage.getInt('levels_completed', 0);
    totalWordsFound = await storage.getInt('total_words_found', 0);
    dailyWins = await storage.getInt('daily_wins', 0);
    dailyStreak = await storage.getInt('login_streak', 0);
    bestDailyStreak = await storage.getInt('best_login_streak', 0);
    bestCombo = await storage.getInt('best_combo', 0);
    freeHints = await storage.getInt('free_hints', 0);
    crownFragments = await storage.getInt('crown_fragments', 0);
    soundEnabled = await storage.getBool('sound_enabled', true);
    isAdFree = await storage.getBool('ad_free', false);
    audio.setEnabled(soundEnabled);
    lastHeartSyncMs = await storage.getInt(
      'last_heart_sync_ms',
      DateTime.now().millisecondsSinceEpoch,
    );

    await _refillHearts();
    await _syncLoginStreak();
    await _loadDailyState();
    await _loadMissions();
    await _migrateContentState();
    await _loadConquestState();
    await account.initialize();

    // Ads and billing remain lazy. Core game, dictionary, missions, economy,
    // progression and sounds all work from bundled/local data while offline.
    purchases.onDelivered = deliverPurchase;

    _startHeartTicker();

    loading = false;
    notifyListeners();
    if (account.signedIn) {
      unawaited(syncCloudProgress());
    }
  }

  String _dateKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  Future<void> _syncLoginStreak() async {
    final now = DateTime.now();
    final today = _dateKey(now);
    final yesterday = _dateKey(now.subtract(const Duration(days: 1)));
    final previous = await storage.getString('last_login_date');

    // Reopening the app multiple times on the same day never increments twice.
    if (previous == today) return;

    dailyStreak = previous == yesterday ? dailyStreak + 1 : 1;
    bestDailyStreak = max(bestDailyStreak, dailyStreak);

    var reward = 0;
    if (dailyStreak % 7 == 0) reward += 5;
    if (dailyStreak % 30 == 0) reward += 20;
    if (reward > 0) {
      coins += reward;
      streakRewardMessage = '🔥 $dailyStreak günlük seri! +$reward altın';
    } else {
      streakRewardMessage = '';
    }

    await storage.setString('last_login_date', today);
    await storage.setInt('login_streak', dailyStreak);
    await storage.setInt('best_login_streak', bestDailyStreak);
    await storage.setInt('coins', coins);
    _scheduleCloudSync();
  }

  Future<void> _loadDailyState() async {
    final now = DateTime.now();
    dailyDateKey = _dateKey(now);
    dailyWord = dictionary.dailyWord(now);
    final storedDate = await storage.getString('daily_date');

    if (storedDate == dailyDateKey) {
      dailyGuesses = await storage.getStringList('daily_guesses');
      dailyFinished = await storage.getBool('daily_finished', false);
      dailyWon = await storage.getBool('daily_won', false);
    } else {
      dailyGuesses = <String>[];
      dailyFinished = false;
      dailyWon = false;
      await storage.setString('daily_date', dailyDateKey);
      await storage.setStringList('daily_guesses', const []);
      await storage.setBool('daily_finished', false);
      await storage.setBool('daily_won', false);
    }
  }

  Future<void> _loadMissions() async {
    final storedDate = await storage.getString('mission_date');
    final raw = await storage.getString('missions_json');
    if (storedDate == dailyDateKey && raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as List<dynamic>;
        dailyMissions = decoded
            .map((item) => DailyMission.fromJson(item as Map<String, dynamic>))
            .toList();
        if (dailyMissions.isNotEmpty) return;
      } catch (_) {
        // Regenerate below if old/corrupt state exists.
      }
    }

    dailyMissions = _generateDailyMissions(DateTime.now());
    await storage.setString('mission_date', dailyDateKey);
    await _persistMissions();
  }

  List<DailyMission> _generateDailyMissions(DateTime date) {
    final dayIndex = DateTime(
      date.year,
      date.month,
      date.day,
    ).difference(DateTime(2026, 1, 1)).inDays.abs();
    final templates = <DailyMission>[
      const DailyMission(
        id: 'bonus',
        type: MissionType.bonusWords,
        title: '4 bonus kelime bul',
        target: 4,
        reward: 3,
        progress: 0,
        claimed: false,
      ),
      const DailyMission(
        id: 'target',
        type: MissionType.targetWords,
        title: '12 hedef kelime bul',
        target: 12,
        reward: 3,
        progress: 0,
        claimed: false,
      ),
      const DailyMission(
        id: 'levels',
        type: MissionType.levels,
        title: '2 bölüm fethet',
        target: 2,
        reward: 4,
        progress: 0,
        claimed: false,
      ),
      const DailyMission(
        id: 'combo',
        type: MissionType.combo,
        title: '4 kelimelik combo yap',
        target: 4,
        reward: 4,
        progress: 0,
        claimed: false,
      ),
      const DailyMission(
        id: 'no_hint',
        type: MissionType.noHintLevel,
        title: 'İpucusuz 1 bölüm bitir',
        target: 1,
        reward: 4,
        progress: 0,
        claimed: false,
      ),
    ];

    return List.generate(
      3,
      (i) => templates[(dayIndex + i * 2) % templates.length],
    );
  }

  Future<void> _persistMissions() async {
    await storage.setString(
      'missions_json',
      jsonEncode(dailyMissions.map((m) => m.toJson()).toList()),
    );
  }

  Future<void> _advanceMission(
    MissionType type, {
    int amount = 1,
    int? atLeast,
  }) async {
    var changed = false;
    dailyMissions = dailyMissions.map((mission) {
      if (mission.type != type || mission.claimed) return mission;
      final next = atLeast == null
          ? min(mission.target, mission.progress + amount)
          : min(mission.target, max(mission.progress, atLeast));
      if (next == mission.progress) return mission;
      changed = true;
      return mission.copyWith(progress: next);
    }).toList();
    if (changed) await _persistMissions();
  }

  Future<bool> claimMission(String id) async {
    final index = dailyMissions.indexWhere((m) => m.id == id);
    if (index < 0) return false;
    final mission = dailyMissions[index];
    if (!mission.completed || mission.claimed) return false;
    coins += mission.reward;
    dailyMissions[index] = mission.copyWith(claimed: true);
    await storage.setInt('coins', coins);
    await _persistMissions();
    notifyListeners();
    return true;
  }

  Future<void> _migrateContentState() async {
    const contentVersion = 5;
    final storedVersion = await storage.getInt('content_version', 0);
    if (storedVersion >= contentVersion) return;

    // V5 changes the deterministic level seed map. Keep the player's economy
    // and reached level, but restart only the currently-open level so old V4
    // found-word/hint state cannot leak into a different V5 board.
    await storage.setInt('active_level_number', -1);
    await storage.setStringList('found_words', const <String>[]);
    await storage.setStringList('bonus_words', const <String>[]);
    await storage.setBool('hint_used_level', false);
    await storage.setString('hints_json', '{}');
    await storage.setInt('content_version', contentVersion);
  }

  Future<void> _loadConquestState() async {
    if (levelNumber < 1) levelNumber = 1;
    if (levelNumber > DictionaryService.maxLevel + 1) {
      levelNumber = DictionaryService.maxLevel + 1;
    }
    currentLevel = dictionary.buildLevel(displayLevel);
    if (campaignCompleted) {
      foundWords.clear();
      bonusWords.clear();
      hints.clear();
      return;
    }
    final savedLevel = await storage.getInt('active_level_number', levelNumber);
    if (savedLevel == levelNumber) {
      foundWords
        ..clear()
        ..addAll(await storage.getStringList('found_words'));
      bonusWords
        ..clear()
        ..addAll(await storage.getStringList('bonus_words'));
      hintUsedThisLevel = await storage.getBool('hint_used_level', false);
      final rawHints = await storage.getString('hints_json');
      if (rawHints != null && rawHints.isNotEmpty) {
        try {
          final decoded = jsonDecode(rawHints) as Map<String, dynamic>;
          hints
            ..clear()
            ..addAll(
              decoded.map(
                (key, value) => MapEntry(
                  key,
                  (value as List<dynamic>).map((e) => e as int).toSet(),
                ),
              ),
            );
        } catch (_) {
          hints.clear();
        }
      }
    } else {
      await _persistConquest();
    }
  }

  Future<void> _refillHearts() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (hearts >= maxNaturalHearts) {
      lastHeartSyncMs = now;
      await storage.setInt('last_heart_sync_ms', now);
      return;
    }

    final elapsed = now - lastHeartSyncMs;
    final refillMs = heartRefill.inMilliseconds;
    final earned = elapsed ~/ refillMs;
    if (earned <= 0) return;

    hearts = min(maxNaturalHearts, hearts + earned);
    lastHeartSyncMs += earned * refillMs;
    await storage.setInt('hearts', hearts);
    await storage.setInt('last_heart_sync_ms', lastHeartSyncMs);
  }

  Duration get nextHeartIn {
    if (hearts >= maxNaturalHearts) return Duration.zero;
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastHeartSyncMs;
    final remaining = heartRefill.inMilliseconds - elapsed;
    return Duration(milliseconds: max(0, remaining));
  }

  String get nextHeartLabel {
    if (hearts >= maxNaturalHearts) return 'Canlar dolu';
    final remaining = nextHeartIn;
    final totalSeconds = max(0, remaining.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '+1 can ${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  void _startHeartTicker() {
    _heartTicker?.cancel();
    _heartTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (hearts >= maxNaturalHearts) return;
      unawaited(_tickHearts());
    });
  }

  Future<void> _tickHearts() async {
    final before = hearts;
    await _refillHearts();
    // Sayaç her saniye değiştiği için can kazanılmasa da arayüzü yenile.
    if (before != hearts || hearts < maxNaturalHearts) {
      notifyListeners();
    }
  }

  List<LetterFeedback> evaluateDaily(String guess) {
    final normalized = TurkishText.normalizeWord(guess);
    final answer = dailyWord;
    final states = List<LetterState>.filled(answer.length, LetterState.absent);
    final remaining = <String, int>{};

    for (var i = 0; i < answer.length; i++) {
      if (normalized[i] == answer[i]) {
        states[i] = LetterState.correct;
      } else {
        remaining[answer[i]] = (remaining[answer[i]] ?? 0) + 1;
      }
    }

    for (var i = 0; i < answer.length; i++) {
      if (states[i] == LetterState.correct) continue;
      final char = normalized[i];
      if ((remaining[char] ?? 0) > 0) {
        states[i] = LetterState.present;
        remaining[char] = remaining[char]! - 1;
      }
    }

    return List.generate(
      answer.length,
      (i) => LetterFeedback(normalized[i], states[i]),
    );
  }

  Future<String?> submitDaily(String guess) async {
    if (dailyFinished) return 'Bugünün kelimesini zaten tamamladın.';
    final normalized = TurkishText.normalizeWord(guess);
    if (normalized.length != 5) return 'Kelime 5 harfli olmalı.';
    if (!dictionary.contains(normalized))
      return 'Bu kelime oyun sözlüğünde bulunamadı.';

    dailyGuesses = [...dailyGuesses, normalized];
    final won = normalized == dailyWord;
    if (won || dailyGuesses.length >= 6) {
      dailyFinished = true;
      dailyWon = won;
      if (won) {
        dailyWins++;
        coins += 30;
        audio.victory();
      } else {
        audio.invalid();
      }
      await storage.setInt('daily_wins', dailyWins);
      await storage.setInt('coins', coins);
    } else {
      if (normalized == dailyWord) {
        audio.target();
      } else {
        audio.select();
      }
    }

    await storage.setStringList('daily_guesses', dailyGuesses);
    await storage.setBool('daily_finished', dailyFinished);
    await storage.setBool('daily_won', dailyWon);
    notifyListeners();
    if (dailyFinished) _scheduleCloudSync();
    return null;
  }

  String dailyShareText() {
    final buffer = StringBuffer('Kelime Fatihi • $dailyDateKey\n');
    for (final guess in dailyGuesses) {
      final feedback = evaluateDaily(guess);
      for (final item in feedback) {
        buffer.write(switch (item.state) {
          LetterState.correct => '🟩',
          LetterState.present => '🟨',
          LetterState.absent => '⬛',
        });
      }
      buffer.writeln();
    }
    buffer.write(dailyWon ? '👑 ${dailyGuesses.length}/6' : '⚔️ X/6');
    return buffer.toString();
  }

  Future<ConquestResult> submitConquestWord(String raw) async {
    if (campaignCompleted) {
      return ConquestResult.invalid(
        '10.000 bölümün tamamını zaten fethettin. 👑',
      );
    }
    final word = TurkishText.normalizeWord(raw);
    if (word.length < 3) {
      comboCount = 0;
      return ConquestResult.invalid('En az 3 harf seçmelisin.');
    }

    if (foundWords.contains(word) || bonusWords.contains(word)) {
      return ConquestResult.duplicate(word);
    }

    if (currentLevel.words.contains(word)) {
      foundWords.add(word);
      totalWordsFound++;
      comboCount++;
      bestCombo = max(bestCombo, comboCount);
      final comboMessage = _comboMessage(comboCount);
      final completed = currentLevel.words.every(foundWords.contains);
      await _advanceMission(MissionType.targetWords);
      await _advanceMission(MissionType.combo, atLeast: comboCount);
      await storage.setInt('total_words_found', totalWordsFound);
      await storage.setInt('best_combo', bestCombo);
      await _persistConquest();
      notifyListeners();
      return ConquestResult.target(
        word,
        completed: completed,
        comboMessage: comboMessage,
      );
    }

    if (dictionary.contains(word)) {
      bonusWords.add(word);
      coins += 1;
      comboCount++;
      bestCombo = max(bestCombo, comboCount);
      final comboMessage = _comboMessage(comboCount);
      await _advanceMission(MissionType.bonusWords);
      await _advanceMission(MissionType.combo, atLeast: comboCount);
      await storage.setInt('coins', coins);
      await storage.setInt('best_combo', bestCombo);
      await _persistConquest();
      notifyListeners();
      return ConquestResult.bonus(word, comboMessage: comboMessage);
    }

    comboCount = 0;
    if (hearts <= 0) return ConquestResult.noHeart();
    final wasFull = hearts >= maxNaturalHearts;
    hearts--;
    if (wasFull && hearts < maxNaturalHearts) {
      lastHeartSyncMs = DateTime.now().millisecondsSinceEpoch;
      await storage.setInt('last_heart_sync_ms', lastHeartSyncMs);
    }
    await storage.setInt('hearts', hearts);
    notifyListeners();
    return ConquestResult.invalid(
      'Kelime bulunamadı. 1 can kaybettin.',
      lostHeart: true,
    );
  }

  String _comboMessage(int combo) => switch (combo) {
    2 => 'İYİ!  ×2',
    3 => 'HARİKA!  ×3',
    4 => 'MUHTEŞEM!  ×4',
    >= 5 => 'KELİME FATİHİ!  ×$combo 👑',
    _ => '',
  };

  Future<HintResult> useHint() async {
    final missing = currentLevel.words
        .where((w) => !foundWords.contains(w))
        .toList();
    if (missing.isEmpty) return const HintResult(false, false);

    final useFree = freeHints > 0;
    if (!useFree && coins < 25) return const HintResult(false, false);

    missing.sort((a, b) => a.length.compareTo(b.length));
    final word = missing.first;
    final revealed = hints.putIfAbsent(word, () => <int>{});
    final nextIndex = List.generate(
      word.length,
      (i) => i,
    ).firstWhere((i) => !revealed.contains(i), orElse: () => -1);
    if (nextIndex < 0) return const HintResult(false, false);

    if (useFree) {
      freeHints--;
      await storage.setInt('free_hints', freeHints);
    } else {
      coins -= 25;
      await storage.setInt('coins', coins);
    }
    hintUsedThisLevel = true;
    revealed.add(nextIndex);
    await _persistConquest();
    notifyListeners();
    return HintResult(true, useFree);
  }

  Future<void> shuffleLetters() async {
    final letters = [...currentLevel.letters]..shuffle(Random());
    currentLevel = ConquestLevel(
      number: currentLevel.number,
      letters: letters,
      words: currentLevel.words,
    );
    notifyListeners();
  }

  Future<ChestReward?> completeLevel() async {
    if (campaignCompleted) return null;
    if (!currentLevel.words.every(foundWords.contains)) return null;

    levelsCompleted++;
    coins += 5;
    await _advanceMission(MissionType.levels);
    if (!hintUsedThisLevel) await _advanceMission(MissionType.noHintLevel);

    ChestReward? chest;
    if (levelsCompleted % 5 == 0) {
      chest = await _grantChest(levelsCompleted ~/ 5);
    }

    if (levelNumber >= DictionaryService.maxLevel) {
      levelNumber = DictionaryService.maxLevel + 1;
    } else {
      levelNumber++;
    }
    foundWords.clear();
    bonusWords.clear();
    hints.clear();
    comboCount = 0;
    hintUsedThisLevel = false;
    currentLevel = dictionary.buildLevel(displayLevel);

    await storage.setInt('levels_completed', levelsCompleted);
    await storage.setInt('level_number', levelNumber);
    await storage.setInt('coins', coins);
    await _persistConquest();
    notifyListeners();

    _scheduleCloudSync();
    return chest;
  }

  Future<ChestReward> _grantChest(int chestNumber) async {
    final type = ChestRewardType
        .values[(chestNumber * 7 + 3) % ChestRewardType.values.length];
    late final ChestReward reward;
    switch (type) {
      case ChestRewardType.heart:
        hearts += 1;
        await storage.setInt('hearts', hearts);
        reward = const ChestReward(
          type: ChestRewardType.heart,
          amount: 1,
          label: '+1 Can',
        );
        break;
      case ChestRewardType.coins:
        coins += 5;
        reward = const ChestReward(
          type: ChestRewardType.coins,
          amount: 5,
          label: '+5 Altın',
        );
        break;
      case ChestRewardType.freeHint:
        freeHints += 1;
        await storage.setInt('free_hints', freeHints);
        reward = const ChestReward(
          type: ChestRewardType.freeHint,
          amount: 1,
          label: '+1 Ücretsiz İpucu',
        );
        break;
      case ChestRewardType.crownFragment:
        crownFragments += 1;
        await storage.setInt('crown_fragments', crownFragments);
        reward = const ChestReward(
          type: ChestRewardType.crownFragment,
          amount: 1,
          label: '+1 Taç Parçası',
        );
        break;
    }
    return reward;
  }

  Future<void> _persistConquest() async {
    await storage.setInt('active_level_number', levelNumber);
    await storage.setStringList('found_words', foundWords.toList());
    await storage.setStringList('bonus_words', bonusWords.toList());
    await storage.setBool('hint_used_level', hintUsedThisLevel);
    await storage.setString(
      'hints_json',
      jsonEncode(hints.map((key, value) => MapEntry(key, value.toList()))),
    );
  }

  Future<bool> buyHeartWithCoins() async {
    const heartPrice = 50;
    if (coins < heartPrice) return false;
    coins -= heartPrice;
    hearts += 1;
    await storage.setInt('coins', coins);
    await storage.setInt('hearts', hearts);
    notifyListeners();
    return true;
  }

  Future<bool> watchAdForHeart() async {
    await ads.initialize();
    final earned = await ads.showRewarded();
    if (earned) {
      hearts += 1;
      await storage.setInt('hearts', hearts);
      notifyListeners();
    }
    return earned;
  }

  Future<void> prepareStore() async {
    await Future.wait([purchases.initialize(), ads.initialize()]);
    notifyListeners();
  }

  Future<void> prepareGameplayAds() async {
    if (isAdFree) return;
    await ads.initialize();
    ads.loadInterstitial();
  }

  Future<bool> showLevelEndAdIfAvailable() async {
    if (isAdFree) return false;
    return ads.showInterstitialIfReady();
  }

  Future<void> restorePurchases() async {
    await purchases.initialize();
    await purchases.restore();
  }

  Future<void> setSoundEnabled(bool value) async {
    soundEnabled = value;
    audio.setEnabled(value);
    await storage.setBool('sound_enabled', value);
    notifyListeners();
  }

  Future<void> addDebugHeart() async {
    hearts += 1;
    await storage.setInt('hearts', hearts);
    notifyListeners();
  }

  Future<void> deliverPurchase(String productId) async {
    if (productId == PurchaseService.productAdFree) {
      isAdFree = true;
      await storage.setBool('ad_free', true);
      notifyListeners();
      return;
    }

    final amount = switch (productId) {
      PurchaseService.productHeart5 => 5,
      PurchaseService.productHeart20 => 20,
      PurchaseService.productHeart50 => 50,
      _ => 0,
    };
    if (amount <= 0) return;
    hearts += amount;
    await storage.setInt('hearts', hearts);
    notifyListeners();
  }

  Future<String?> signInWithGoogle() async {
    final error = await account.signInWithGoogle();
    if (error == null && account.signedIn) await syncCloudProgress();
    notifyListeners();
    return error;
  }

  Future<String?> signInWithApple() async {
    final error = await account.signInWithApple();
    if (error == null && account.signedIn) await syncCloudProgress();
    notifyListeners();
    return error;
  }

  Future<void> signOutAccount() async {
    await account.signOut();
    cloudStatusMessage = '';
    notifyListeners();
  }

  Future<String?> deleteAccount() async {
    final error = await account.deleteAccount();
    if (error == null) cloudStatusMessage = '';
    notifyListeners();
    return error;
  }

  Future<void> syncCloudProgress() async {
    if (!account.signedIn || cloudSyncing) return;
    cloudSyncing = true;
    notifyListeners();
    try {
      final cloud = await account.loadProgress();
      if (cloud != null) {
        final cloudLevel = (cloud['levelNumber'] as num?)?.toInt() ?? 1;
        if (cloudLevel > levelNumber) {
          levelNumber = min(cloudLevel, DictionaryService.maxLevel + 1);
          levelsCompleted = max(
            levelsCompleted,
            (cloud['levelsCompleted'] as num?)?.toInt() ?? 0,
          );
          totalWordsFound = max(
            totalWordsFound,
            (cloud['totalWordsFound'] as num?)?.toInt() ?? 0,
          );
          dailyWins = max(
            dailyWins,
            (cloud['dailyWins'] as num?)?.toInt() ?? 0,
          );
          bestDailyStreak = max(
            bestDailyStreak,
            (cloud['bestDailyStreak'] as num?)?.toInt() ?? 0,
          );
          bestCombo = max(
            bestCombo,
            (cloud['bestCombo'] as num?)?.toInt() ?? 0,
          );
          crownFragments = max(
            crownFragments,
            (cloud['crownFragments'] as num?)?.toInt() ?? 0,
          );
          await storage.setInt('level_number', levelNumber);
          await storage.setInt('levels_completed', levelsCompleted);
          await storage.setInt('total_words_found', totalWordsFound);
          await storage.setInt('daily_wins', dailyWins);
          await storage.setInt('best_login_streak', bestDailyStreak);
          await storage.setInt('best_combo', bestCombo);
          await storage.setInt('crown_fragments', crownFragments);
          await storage.setInt('active_level_number', -1);
          await storage.setStringList('found_words', const <String>[]);
          await storage.setStringList('bonus_words', const <String>[]);
          await _loadConquestState();
        }
      }
      await account.saveProgress(_cloudProgressMap());
      cloudStatusMessage = 'Bulut yedeği güncel';
    } finally {
      cloudSyncing = false;
      notifyListeners();
    }
  }

  Map<String, dynamic> _cloudProgressMap() => <String, dynamic>{
    'levelNumber': levelNumber,
    'levelsCompleted': levelsCompleted,
    'totalWordsFound': totalWordsFound,
    'dailyWins': dailyWins,
    'bestDailyStreak': bestDailyStreak,
    'bestCombo': bestCombo,
    'crownFragments': crownFragments,
  };

  void _scheduleCloudSync() {
    if (!account.signedIn) return;
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer(const Duration(seconds: 2), () {
      unawaited(syncCloudProgress());
    });
  }

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _heartTicker?.cancel();
    super.dispose();
  }

  String hintDisplay(String word) {
    if (foundWords.contains(word)) return TurkishText.upper(word);
    final revealed = hints[word] ?? <int>{};
    return List.generate(
      word.length,
      (i) => revealed.contains(i) ? TurkishText.upper(word[i]) : '•',
    ).join(' ');
  }
}

class HintResult {
  const HintResult(this.used, this.usedFreeHint);
  final bool used;
  final bool usedFreeHint;
}

class ConquestResult {
  const ConquestResult._({
    required this.message,
    required this.isTarget,
    required this.isBonus,
    required this.completed,
    required this.lostHeart,
    required this.noHearts,
    required this.isDuplicate,
    required this.comboMessage,
  });

  final String message;
  final bool isTarget;
  final bool isBonus;
  final bool completed;
  final bool lostHeart;
  final bool noHearts;
  final bool isDuplicate;
  final String comboMessage;

  factory ConquestResult.target(
    String word, {
    required bool completed,
    required String comboMessage,
  }) => ConquestResult._(
    message: completed
        ? 'Bölge fethedildi!'
        : '${TurkishText.upper(word)} bulundu!',
    isTarget: true,
    isBonus: false,
    completed: completed,
    lostHeart: false,
    noHearts: false,
    isDuplicate: false,
    comboMessage: comboMessage,
  );

  factory ConquestResult.bonus(String word, {required String comboMessage}) =>
      ConquestResult._(
        message: '${TurkishText.upper(word)} bonus! +1 altın',
        isTarget: false,
        isBonus: true,
        completed: false,
        lostHeart: false,
        noHearts: false,
        isDuplicate: false,
        comboMessage: comboMessage,
      );

  factory ConquestResult.duplicate(String word) => ConquestResult._(
    message: '${TurkishText.upper(word)} bu bölümde zaten kullanıldı.',
    isTarget: false,
    isBonus: false,
    completed: false,
    lostHeart: false,
    noHearts: false,
    isDuplicate: true,
    comboMessage: '',
  );

  factory ConquestResult.invalid(String message, {bool lostHeart = false}) =>
      ConquestResult._(
        message: message,
        isTarget: false,
        isBonus: false,
        completed: false,
        lostHeart: lostHeart,
        noHearts: false,
        isDuplicate: false,
        comboMessage: '',
      );

  factory ConquestResult.noHeart() => const ConquestResult._(
    message: 'Canın kalmadı. Reklam izle veya mağazadan can al.',
    isTarget: false,
    isBonus: false,
    completed: false,
    lostHeart: false,
    noHearts: true,
    isDuplicate: false,
    comboMessage: '',
  );
}
