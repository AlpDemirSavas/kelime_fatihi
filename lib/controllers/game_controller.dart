import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../core/turkish_text.dart';
import '../models/chest_reward.dart';
import '../models/competition.dart';
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
  int dailyPuzzleStreak = 0;
  int bestDailyPuzzleStreak = 0;
  String streakRewardMessage = '';
  String lastRejectedWord = '';
  LevelMilestoneReward? _pendingMilestoneReward;
  PerfectConquestReward? _pendingPerfectReward;
  int lastHeartSyncMs = 0;
  int comboCount = 0;
  int bestCombo = 0;
  int perfectConquests = 0;
  int bonusTreasureProgress = 0;
  int bonusTreasuresOpened = 0;
  int freeHints = 0;
  int crownFragments = 0;
  int mistakesThisLevel = 0;
  String dailyPuzzleRewardMessage = '';
  bool soundEnabled = true;
  bool hapticsEnabled = true;
  bool reduceMotionEnabled = false;
  bool systemReduceMotion = false;
  bool hintUsedThisLevel = false;
  bool isAdFree = false;
  bool cloudSyncing = false;
  String cloudStatusMessage = '';
  int weeklyScore = 0;
  int seasonScore = 0;
  String competitionWeekKey = '';
  String competitionSeasonKey = '';
  bool socialEnabled = false;
  bool socialSyncing = false;
  String socialStatusMessage = '';
  String friendCode = '';
  String socialUsername = '';
  String _socialOwnerUid = '';
  Timer? _cloudSyncTimer;
  Timer? _socialSyncTimer;
  Timer? _heartTicker;
  Timer? _comboExpiryTimer;

  static const int maxNaturalHearts = 5;
  static const int bonusTreasureTarget = 25;
  static const Duration heartRefill = Duration(minutes: 20);
  static const Duration comboWindow = Duration(seconds: 12);
  static const String _pendingLevelCompletionKey =
      'pending_level_completion_v1';
  static const String _pendingDailyCompetitionKey =
      'pending_daily_competition_v1';

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

  bool get effectiveReduceMotion => reduceMotionEnabled || systemReduceMotion;
  bool get campaignCompleted => levelNumber > DictionaryService.maxLevel;
  int get displayLevel => min(levelNumber, DictionaryService.maxLevel);
  ConquestRegion get currentRegion => ConquestRegion.forLevel(displayLevel);
  int get crownsUnlocked => crownFragments ~/ 5;
  int get remainingTargetWords => currentLevel.words.length - foundWords.length;
  bool get perfectEligible => !hintUsedThisLevel && mistakesThisLevel == 0;
  bool get signedIn => account.signedIn;
  String get accountName => account.displayName;
  String get accountEmail => account.email;
  LeagueTier get currentLeague => LeagueTier.forScore(seasonScore);
  double get leagueProgress {
    final tier = currentLeague;
    final next = tier.nextThreshold;
    if (next == null) return 1;
    final span = next - tier.lowerThreshold;
    if (span <= 0) return 1;
    return ((seasonScore - tier.lowerThreshold) / span).clamp(0.0, 1.0).toDouble();
  }
  int get regionProgress {
    if (campaignCompleted) return ConquestRegion.regionSize;
    return currentRegion.progressFor(levelNumber) - 1;
  }
  double get regionProgressRatio =>
      (regionProgress / ConquestRegion.regionSize).clamp(0.0, 1.0).toDouble();
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
    dailyPuzzleStreak = await storage.getInt('daily_puzzle_streak', 0);
    bestDailyPuzzleStreak = await storage.getInt(
      'best_daily_puzzle_streak',
      0,
    );
    bestDailyStreak = await storage.getInt('best_login_streak', 0);
    bestCombo = await storage.getInt('best_combo', 0);
    perfectConquests = await storage.getInt('perfect_conquests', 0);
    bonusTreasureProgress = await storage.getInt('bonus_treasure_progress', 0);
    bonusTreasuresOpened = await storage.getInt('bonus_treasures_opened', 0);
    freeHints = await storage.getInt('free_hints', 0);
    crownFragments = await storage.getInt('crown_fragments', 0);
    soundEnabled = await storage.getBool('sound_enabled', true);
    hapticsEnabled = await storage.getBool('haptics_enabled', true);
    reduceMotionEnabled = await storage.getBool('reduce_motion_enabled', false);
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
    await _recoverPendingLevelCompletion();
    await _loadConquestState();
    await _recoverLegacyCompletedBoard();
    await account.initialize();
    await _loadCompetitionState();
    await _recoverPendingDailyCompetitionAward();
    await _reconcileSocialOwnerAfterSignIn();

    // Ads and billing remain lazy. Core game, dictionary, missions, economy,
    // progression and sounds all work from bundled/local data while offline.
    purchases.onDelivered = deliverPurchase;

    _startHeartTicker();

    loading = false;
    notifyListeners();
    if (account.signedIn) {
      unawaited(syncCloudProgress());
      if (socialEnabled) unawaited(syncSocialProfile());
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

  Future<void> _loadDailyState({DateTime? at}) async {
    final now = at ?? DateTime.now();
    dailyDateKey = _dateKey(now);
    dailyWord = dictionary.dailyWord(now);
    dailyPuzzleRewardMessage = '';
    final storedDate = await storage.getString('daily_date');

    if (storedDate == dailyDateKey) {
      dailyGuesses = await storage.getStringList('daily_guesses');
      dailyFinished = await storage.getBool('daily_finished', false);
      dailyWon = await storage.getBool('daily_won', false);
      if (dailyFinished) {
        await _syncDailyPuzzleStreakForCompletedDay();
      }
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

  Future<bool> refreshDailyStateIfNeeded() async {
    final now = DateTime.now();
    if (_dateKey(now) == dailyDateKey) return false;

    await _loadDailyState(at: now);
    await _loadMissions(at: now);
    notifyListeners();
    return true;
  }

  Future<void> _syncDailyPuzzleStreakForCompletedDay() async {
    final lastProcessedDate = await storage.getString(
      'last_daily_result_date',
    );
    if (lastProcessedDate == dailyDateKey) return;

    dailyPuzzleRewardMessage = '';
    if (dailyWon) {
      final yesterday = _dateKey(
        DateTime.now().subtract(const Duration(days: 1)),
      );
      final lastWinDate = await storage.getString('last_daily_win_date');
      dailyPuzzleStreak = lastWinDate == yesterday
          ? dailyPuzzleStreak + 1
          : 1;
      bestDailyPuzzleStreak = max(
        bestDailyPuzzleStreak,
        dailyPuzzleStreak,
      );
      await storage.setString('last_daily_win_date', dailyDateKey);

      final streakReward = switch (dailyPuzzleStreak) {
        7 => 10,
        30 => 30,
        100 => 100,
        _ => 0,
      };
      if (streakReward > 0) {
        coins += streakReward;
        dailyPuzzleRewardMessage =
            '🔥 $dailyPuzzleStreak günlük Günün Kelimesi serisi! +$streakReward altın';
        await storage.setInt('coins', coins);
      }
    } else {
      dailyPuzzleStreak = 0;
    }

    await storage.setString('last_daily_result_date', dailyDateKey);
    await storage.setInt('daily_puzzle_streak', dailyPuzzleStreak);
    await storage.setInt(
      'best_daily_puzzle_streak',
      bestDailyPuzzleStreak,
    );
  }

  Future<void> _loadMissions({DateTime? at}) async {
    final now = at ?? DateTime.now();
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

    dailyMissions = _generateDailyMissions(now);
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

  int _appStoreV14TargetCount(int level) {
    if (level < 100) return 5;
    if (level < 1000) return 6;
    if (level < 3000) return 7;
    if (level < 5500) return 8;
    if (level < 8000) return 9;
    return 10;
  }

  Future<void> _recoverAppStoreV14CompletedBoard() async {
    if (levelNumber < 1 || levelNumber > 10000) return;

    final activeLevel = await storage.getInt(
      'active_level_number',
      levelNumber,
    );
    if (activeLevel != levelNumber) return;

    final storedFoundWords = await storage.getStringList('found_words');
    final expectedTargetCount = _appStoreV14TargetCount(levelNumber);
    if (storedFoundWords.toSet().length < expectedTargetCount) return;

    final oldHintUsed = await storage.getBool('hint_used_level', false);
    final completedLevelNumber = levelNumber;
    final nextLevelsCompleted = levelsCompleted + 1;
    final nextLevelNumber = levelNumber >= DictionaryService.maxLevel
        ? DictionaryService.maxLevel + 1
        : levelNumber + 1;
    final milestone = _milestoneRewardFor(completedLevelNumber);
    final chest = _chestRewardFor(nextLevelsCompleted);

    var nextCoins = coins + 5;
    var nextHearts = hearts;
    var nextFreeHints = freeHints;
    var nextCrownFragments = crownFragments;

    if (milestone != null) {
      nextCoins += milestone.coins;
      nextHearts += milestone.hearts;
      nextFreeHints += milestone.freeHints;
      nextCrownFragments += milestone.crownFragments;
    }
    if (chest != null) {
      switch (chest.type) {
        case ChestRewardType.heart:
          nextHearts += chest.amount;
          break;
        case ChestRewardType.coins:
          nextCoins += chest.amount;
          break;
        case ChestRewardType.freeHint:
          nextFreeHints += chest.amount;
          break;
        case ChestRewardType.crownFragment:
          nextCrownFragments += chest.amount;
          break;
      }
    }

    var nextMissions = _missionSnapshotAfterProgress(
      dailyMissions,
      MissionType.levels,
    );
    if (!oldHintUsed) {
      nextMissions = _missionSnapshotAfterProgress(
        nextMissions,
        MissionType.noHintLevel,
      );
    }

    // App Store v14 did not have Kusursuz Fetih. Do not grant that newer
    // reward retroactively; preserve the exact old completion economy.
    final plan = _LevelCompletionPlan(
      completedLevelNumber: completedLevelNumber,
      nextLevelNumber: nextLevelNumber,
      nextLevelsCompleted: nextLevelsCompleted,
      nextCoins: nextCoins,
      nextHearts: nextHearts,
      nextFreeHints: nextFreeHints,
      nextCrownFragments: nextCrownFragments,
      nextPerfectConquests: perfectConquests,
      wasPerfect: false,
      missionDateKey: dailyDateKey,
      missions: nextMissions,
    );

    await storage.setString(
      _pendingLevelCompletionKey,
      jsonEncode(plan.toJson()),
    );
    await _applyLevelCompletionPlan(plan, exposeRewards: false);
    await storage.setString(_pendingLevelCompletionKey, '');
  }

  Future<void> _migrateContentState() async {
    const contentVersion = 17;
    final storedVersion = await storage.getInt('content_version', 0);
    if (storedVersion >= contentVersion) return;

    // The live App Store build is content v14. Recover its historical
    // "all targets found but level not advanced" ad-interruption state before
    // V15/V16 clear open-board data when campaign mappings change.
    if (storedVersion == 14) {
      await _recoverAppStoreV14CompletedBoard();
    }

    if (storedVersion < 11) {
      // V11 remapped the 8,000-level campaign for the 20/30-level cooldown.
      // Only users coming from an older campaign need their open board reset.
      await storage.setInt('active_level_number', -1);
      await storage.setStringList('found_words', const <String>[]);
      await storage.setStringList('bonus_words', const <String>[]);
      await storage.setBool('hint_used_level', false);
      await storage.setString('hints_json', '{}');
    }

    // V12 added engagement state without remapping levels.
    if (storedVersion < 12) {
      await storage.setInt('mistakes_this_level', 0);
    }

    if (storedVersion < 15) {
      // The live App Store campaign reached content version 14. V15 moved
      // every player onto the 8,000-level App Store-superset campaign.
      // Preserve permanent progress/economy, but never reuse found-word or
      // hint state from a differently mapped open board.
      await storage.setInt('active_level_number', -1);
      await storage.setStringList('found_words', const <String>[]);
      await storage.setStringList('bonus_words', const <String>[]);
      await storage.setBool('hint_used_level', false);
      await storage.setInt('mistakes_this_level', 0);
      await storage.setString('hints_json', '{}');
    }

    if (storedVersion < 16) {
      // V16 keeps the 8,000-level structure but performs the final
      // wheel/mandatory-word quality rebalance. Keep permanent progress and
      // economy, but reset only the open-board state because its seed/targets
      // may have changed.
      await storage.setInt('active_level_number', -1);
      await storage.setStringList('found_words', const <String>[]);
      await storage.setStringList('bonus_words', const <String>[]);
      await storage.setBool('hint_used_level', false);
      await storage.setInt('mistakes_this_level', 0);
      await storage.setString('hints_json', '{}');
    }

    if (storedVersion < 17) {
      // V17 sosyal ligler ve görsel progression katmanıdır. Kampanya seed/target
      // eşlemesi değişmediği için kullanıcının açık tahtasını, canını, parasını
      // veya bulunduğu bölümü sıfırlamayız.
    }

    await storage.setInt('content_version', contentVersion);
  }

  Future<void> _loadConquestState() async {
    final storedLevelNumber = levelNumber;
    if (levelNumber < 1) levelNumber = 1;
    if (levelNumber > DictionaryService.maxLevel + 1) {
      levelNumber = DictionaryService.maxLevel + 1;
    }
    if (levelNumber != storedLevelNumber) {
      await storage.setInt('level_number', levelNumber);
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
      mistakesThisLevel = await storage.getInt('mistakes_this_level', 0);
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
      mistakesThisLevel = 0;
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
      await _syncDailyPuzzleStreakForCompletedDay();
      if (won) await _awardDailyCompetition();
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
    buffer.write(' • 🔥 $dailyPuzzleStreak • Rekor $bestDailyPuzzleStreak');
    return buffer.toString();
  }

  Future<ConquestResult> submitConquestWord(String raw) async {
    if (campaignCompleted) {
      return ConquestResult.invalid(
        '8.000 bölümün tamamını zaten fethettin. 👑',
      );
    }
    final word = TurkishText.normalizeWord(raw);
    if (word.length < 3) {
      _comboExpiryTimer?.cancel();
      comboCount = 0;
      return ConquestResult.invalid('En az 3 harf seçmelisin.');
    }

    // Can sıfırken doğru veya bonus kelime girerek bölüme devam edilmesine
    // izin verme. Can kontrolü hedef/bonus doğrulamasından önce yapılmalı.
    if (hearts <= 0) {
      _comboExpiryTimer?.cancel();
      comboCount = 0;
      return ConquestResult.noHeart();
    }

    if (foundWords.contains(word) || bonusWords.contains(word)) {
      return ConquestResult.duplicate(word);
    }

    if (currentLevel.words.contains(word)) {
      lastRejectedWord = '';
      foundWords.add(word);
      totalWordsFound++;
      comboCount++;
      _armComboExpiry();
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

    final isProperName = dictionary.isProperName(word);
    if (dictionary.contains(word) || isProperName) {
      lastRejectedWord = '';
      bonusWords.add(word);
      coins += 1;
      comboCount++;
      _armComboExpiry();
      bestCombo = max(bestCombo, comboCount);
      final comboMessage = _comboMessage(comboCount);
      await _advanceMission(MissionType.bonusWords);
      await _advanceMission(MissionType.combo, atLeast: comboCount);

      bonusTreasureProgress++;
      var treasureOpened = false;
      if (bonusTreasureProgress >= bonusTreasureTarget) {
        bonusTreasureProgress -= bonusTreasureTarget;
        bonusTreasuresOpened++;
        coins += 20;
        treasureOpened = true;
      }

      await storage.setInt('coins', coins);
      await storage.setInt('best_combo', bestCombo);
      await storage.setInt('bonus_treasure_progress', bonusTreasureProgress);
      await storage.setInt('bonus_treasures_opened', bonusTreasuresOpened);
      await _persistConquest();
      notifyListeners();
      return isProperName
          ? ConquestResult.properNameBonus(
              word,
              comboMessage: comboMessage,
              bonusTreasureOpened: treasureOpened,
            )
          : ConquestResult.bonus(
              word,
              comboMessage: comboMessage,
              bonusTreasureOpened: treasureOpened,
            );
    }

    _comboExpiryTimer?.cancel();
    comboCount = 0;
    mistakesThisLevel++;
    lastRejectedWord = word;
    final wasFull = hearts >= maxNaturalHearts;
    hearts--;
    if (wasFull && hearts < maxNaturalHearts) {
      lastHeartSyncMs = DateTime.now().millisecondsSinceEpoch;
      await storage.setInt('last_heart_sync_ms', lastHeartSyncMs);
    }
    await storage.setInt('hearts', hearts);
    await storage.setInt('mistakes_this_level', mistakesThisLevel);
    notifyListeners();
    return ConquestResult.invalid(
      'Kelime bulunamadı. 1 can kaybettin.',
      lostHeart: true,
    );
  }

  void _armComboExpiry() {
    _comboExpiryTimer?.cancel();
    _comboExpiryTimer = Timer(comboWindow, () {
      if (comboCount == 0) return;
      comboCount = 0;
      notifyListeners();
    });
  }

  String _comboMessage(int combo) => switch (combo) {
    2 => 'İYİ!  ×2',
    3 => 'HARİKA!  ×3',
    4 => 'MUHTEŞEM!  ×4',
    >= 5 => 'KELİME FATİHİ!  ×$combo 👑',
    _ => '',
  };

  Future<HintResult> useHint([
    ConquestHintType type = ConquestHintType.revealLetter,
  ]) async {
    final missing = currentLevel.words
        .where((w) => !foundWords.contains(w))
        .toList();
    if (missing.isEmpty) return const HintResult(false, false);

    missing.sort((a, b) => a.length.compareTo(b.length));
    String word;
    if (type == ConquestHintType.firstLetter) {
      final candidates = missing
          .where((w) => !(hints[w]?.contains(0) ?? false))
          .toList();
      if (candidates.isEmpty) {
        return const HintResult(
          false,
          false,
          message: 'Kalan kelimelerin ilk harfleri zaten açık.',
        );
      }
      word = candidates.first;
    } else {
      word = missing.first;
    }
    final revealed = hints.putIfAbsent(word, () => <int>{});

    final baseCost = switch (type) {
      ConquestHintType.revealLetter => 25,
      ConquestHintType.firstLetter => 20,
      ConquestHintType.revealTwoLetters => 40,
    };
    final useFree = type == ConquestHintType.revealLetter && freeHints > 0;
    if (!useFree && coins < baseCost) {
      return HintResult(
        false,
        false,
        message: 'Bu ipucu için $baseCost altın gerekiyor.',
      );
    }

    final hidden = List.generate(word.length, (i) => i)
        .where((i) => !revealed.contains(i))
        .toList();
    if (hidden.isEmpty) return const HintResult(false, false);

    final indexes = switch (type) {
      ConquestHintType.firstLetter => const <int>[0],
      ConquestHintType.revealTwoLetters => hidden.take(2).toList(),
      ConquestHintType.revealLetter => <int>[hidden.first],
    };

    if (useFree) {
      freeHints--;
      await storage.setInt('free_hints', freeHints);
    } else {
      coins -= baseCost;
      await storage.setInt('coins', coins);
    }

    hintUsedThisLevel = true;
    revealed.addAll(indexes);
    await _persistConquest();
    notifyListeners();

    final label = switch (type) {
      ConquestHintType.revealLetter => 'Bir harf açıldı',
      ConquestHintType.firstLetter => 'İlk harf açıldı',
      ConquestHintType.revealTwoLetters => '${indexes.length} harf açıldı',
    };
    return HintResult(
      true,
      useFree,
      spentCoins: useFree ? 0 : baseCost,
      revealedCount: indexes.length,
      message: useFree ? '$label · ücretsiz ipucu' : '$label · −$baseCost altın',
    );
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
    await _ensureCompetitionPeriods();

    // Bölüm sonucu ekrandan/reklamdan bağımsız olarak önce kalıcı hale gelir.
    // Journal, uygulama tam kayıt sırasında öldürülse bile işlemin aynı mutlak
    // değerlerle tekrar uygulanabilmesini sağlar; ödül iki kez verilmez.
    final plan = _buildLevelCompletionPlan();
    await storage.setString(
      _pendingLevelCompletionKey,
      jsonEncode(plan.toJson()),
    );
    await _applyLevelCompletionPlan(plan, exposeRewards: true);
    await storage.setString(_pendingLevelCompletionKey, '');

    _scheduleCloudSync();
    _scheduleSocialSync();
    return _chestRewardFor(plan.nextLevelsCompleted);
  }

  _LevelCompletionPlan _buildLevelCompletionPlan() {
    final completedLevelNumber = currentLevel.number;
    final nextLevelsCompleted = levelsCompleted + 1;
    final nextLevelNumber = levelNumber >= DictionaryService.maxLevel
        ? DictionaryService.maxLevel + 1
        : levelNumber + 1;
    final wasPerfect = perfectEligible;
    final milestone = _milestoneRewardFor(completedLevelNumber);
    final chest = _chestRewardFor(nextLevelsCompleted);

    var nextCoins = coins + 5;
    var nextHearts = hearts;
    var nextFreeHints = freeHints;
    var nextCrownFragments = crownFragments;
    var nextPerfectConquests = perfectConquests;

    if (wasPerfect) {
      nextCoins += 5;
      nextPerfectConquests++;
    }
    if (milestone != null) {
      nextCoins += milestone.coins;
      nextHearts += milestone.hearts;
      nextFreeHints += milestone.freeHints;
      nextCrownFragments += milestone.crownFragments;
    }
    if (chest != null) {
      switch (chest.type) {
        case ChestRewardType.heart:
          nextHearts += chest.amount;
          break;
        case ChestRewardType.coins:
          nextCoins += chest.amount;
          break;
        case ChestRewardType.freeHint:
          nextFreeHints += chest.amount;
          break;
        case ChestRewardType.crownFragment:
          nextCrownFragments += chest.amount;
          break;
      }
    }

    var nextMissions = _missionSnapshotAfterProgress(
      dailyMissions,
      MissionType.levels,
    );
    if (!hintUsedThisLevel) {
      nextMissions = _missionSnapshotAfterProgress(
        nextMissions,
        MissionType.noHintLevel,
      );
    }

    final competitionDelta = CompetitionScoring.levelCompletion(
      bonusWords: bonusWords.length,
      perfect: wasPerfect,
    );

    return _LevelCompletionPlan(
      completedLevelNumber: completedLevelNumber,
      nextLevelNumber: nextLevelNumber,
      nextLevelsCompleted: nextLevelsCompleted,
      nextCoins: nextCoins,
      nextHearts: nextHearts,
      nextFreeHints: nextFreeHints,
      nextCrownFragments: nextCrownFragments,
      nextPerfectConquests: nextPerfectConquests,
      wasPerfect: wasPerfect,
      missionDateKey: dailyDateKey,
      missions: nextMissions,
      socialWeekKey: competitionWeekKey,
      socialSeasonKey: competitionSeasonKey,
      nextWeeklyScore: weeklyScore + competitionDelta,
      nextSeasonScore: seasonScore + competitionDelta,
    );
  }

  List<DailyMission> _missionSnapshotAfterProgress(
    List<DailyMission> source,
    MissionType type,
  ) {
    return source.map((mission) {
      if (mission.type != type || mission.claimed) return mission;
      return mission.copyWith(
        progress: min(mission.target, mission.progress + 1),
      );
    }).toList();
  }

  Future<void> _applyLevelCompletionPlan(
    _LevelCompletionPlan plan, {
    required bool exposeRewards,
  }) async {
    levelNumber = plan.nextLevelNumber;
    levelsCompleted = plan.nextLevelsCompleted;
    coins = plan.nextCoins;
    hearts = plan.nextHearts;
    freeHints = plan.nextFreeHints;
    crownFragments = plan.nextCrownFragments;
    perfectConquests = plan.nextPerfectConquests;
    if (plan.nextWeeklyScore != null &&
        plan.nextSeasonScore != null &&
        plan.socialWeekKey != null &&
        plan.socialSeasonKey != null) {
      weeklyScore = plan.nextWeeklyScore!;
      seasonScore = plan.nextSeasonScore!;
      competitionWeekKey = plan.socialWeekKey!;
      competitionSeasonKey = plan.socialSeasonKey!;
    }
    if (dailyDateKey == plan.missionDateKey) {
      dailyMissions = plan.missions;
    }

    foundWords.clear();
    bonusWords.clear();
    hints.clear();
    _comboExpiryTimer?.cancel();
    comboCount = 0;
    lastRejectedWord = '';
    hintUsedThisLevel = false;
    mistakesThisLevel = 0;
    currentLevel = dictionary.buildLevel(displayLevel);

    if (exposeRewards) {
      _pendingMilestoneReward = _milestoneRewardFor(
        plan.completedLevelNumber,
      );
      _pendingPerfectReward = plan.wasPerfect
          ? const PerfectConquestReward(coins: 5, message: '+5 altın')
          : null;
    } else {
      _pendingMilestoneReward = null;
      _pendingPerfectReward = null;
    }

    // Journal silinmeden önce bütün değerler mutlak olarak yazılır. Aynı plan
    // recovery sırasında tekrar uygulanırsa artışlar ikinci kez gerçekleşmez.
    await storage.setInt('levels_completed', levelsCompleted);
    await storage.setInt('level_number', levelNumber);
    await storage.setInt('coins', coins);
    await storage.setInt('hearts', hearts);
    await storage.setInt('free_hints', freeHints);
    await storage.setInt('crown_fragments', crownFragments);
    await storage.setInt('perfect_conquests', perfectConquests);
    await storage.setInt('mistakes_this_level', mistakesThisLevel);
    if (plan.nextWeeklyScore != null) {
      await _persistCompetitionState();
    }
    await _persistMissions();
    await _persistConquest();
    notifyListeners();
  }

  Future<void> _recoverPendingLevelCompletion() async {
    final raw = await storage.getString(_pendingLevelCompletionKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await storage.setString(_pendingLevelCompletionKey, '');
        return;
      }
      final plan = _LevelCompletionPlan.fromJson(decoded);
      await _applyLevelCompletionPlan(plan, exposeRewards: false);
      await storage.setString(_pendingLevelCompletionKey, '');
    } catch (_) {
      // Bozuk bir journal oyunu kilitlemesin. Eski yeşil-tahta recovery'si
      // _loadConquestState sonrasında ayrıca çalışır.
      await storage.setString(_pendingLevelCompletionKey, '');
    }
  }

  Future<void> _recoverLegacyCompletedBoard() async {
    if (campaignCompleted || currentLevel.words.isEmpty) return;
    if (!currentLevel.words.every(foundWords.contains)) return;

    // Eski akışta son kelime kaydediliyor, ardından reklam açılıyor ve ancak
    // reklam kapandıktan sonra completeLevel çağrılıyordu. Reklam sırasında
    // uygulama öldürülürse tüm kutular yeşil kalıyor fakat level_number
    // ilerlemiyordu. Böyle bir kayıt bulunursa reklamsız ve güvenli biçimde
    // bir kez tamamla.
    await completeLevel();
    _pendingMilestoneReward = null;
    _pendingPerfectReward = null;
  }

  bool isMilestoneLevel(int level) {
    if (level == 10 || level == 25 || level == 50) return true;
    return level >= 100 && level % 100 == 0;
  }

  LevelMilestoneReward? takePendingMilestoneReward() {
    final reward = _pendingMilestoneReward;
    _pendingMilestoneReward = null;
    return reward;
  }

  PerfectConquestReward? takePendingPerfectReward() {
    final reward = _pendingPerfectReward;
    _pendingPerfectReward = null;
    return reward;
  }

  LevelMilestoneReward? _milestoneRewardFor(int level) {
    if (level >= 100 && level % 100 == 0) {
      return LevelMilestoneReward(
        level: level,
        title: '$level Bölümlük Büyük Fetih',
        message: '+50 altın ve +1 taç parçası',
        coins: 50,
        crownFragments: 1,
      );
    }
    if (level == 50) {
      return const LevelMilestoneReward(
        level: 50,
        title: '50 Bölümlük Usta Fetih',
        message: '+25 altın ve +1 can',
        coins: 25,
        hearts: 1,
      );
    }
    if (level == 25) {
      return const LevelMilestoneReward(
        level: 25,
        title: '25 Bölümlük Güçlü Başlangıç',
        message: '+15 altın ve +1 ücretsiz ipucu',
        coins: 15,
        freeHints: 1,
      );
    }
    if (level == 10) {
      return const LevelMilestoneReward(
        level: 10,
        title: 'İlk 10 Bölüm Fethedildi',
        message: '+10 altın',
        coins: 10,
      );
    }
    return null;
  }

  ChestReward? _chestRewardFor(int completedLevels) {
    if (completedLevels % 5 != 0) return null;

    final chestNumber = completedLevels ~/ 5;
    final tier = completedLevels % 100 == 0
        ? ChestRewardTier.region
        : completedLevels % 50 == 0
        ? ChestRewardTier.master
        : completedLevels % 10 == 0
        ? ChestRewardTier.conquest
        : ChestRewardTier.scout;
    final type = ChestRewardType
        .values[(chestNumber * 7 + 3) % ChestRewardType.values.length];

    return switch (type) {
      ChestRewardType.heart => ChestReward(
        type: type,
        amount: 1,
        label: '+1 Can',
        tier: tier,
      ),
      ChestRewardType.coins => ChestReward(
        type: type,
        amount: 5,
        label: '+5 Altın',
        tier: tier,
      ),
      ChestRewardType.freeHint => ChestReward(
        type: type,
        amount: 1,
        label: '+1 Ücretsiz İpucu',
        tier: tier,
      ),
      ChestRewardType.crownFragment => ChestReward(
        type: type,
        amount: 1,
        label: '+1 Taç Parçası',
        tier: tier,
      ),
    };
  }

  Future<void> _persistConquest() async {
    await storage.setInt('active_level_number', levelNumber);
    await storage.setStringList('found_words', foundWords.toList());
    await storage.setStringList('bonus_words', bonusWords.toList());
    await storage.setBool('hint_used_level', hintUsedThisLevel);
    await storage.setInt('mistakes_this_level', mistakesThisLevel);
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

  /// Günün Kelimesi yalnız bir kez tamamlanabildiği için, tur kazanıldığında
  /// veya altı hak bittiğinde tek bir hazır interstitial gösterir. Reklam
  /// hazır değilse günlük sonucu veya offline oynanışı bekletmez.
  Future<bool> showDailyEndAdIfAvailable() async {
    if (isAdFree) return false;
    return ads.showInterstitialWhenReady();
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

  Future<void> setHapticsEnabled(bool value) async {
    hapticsEnabled = value;
    await storage.setBool('haptics_enabled', value);
    if (value) {
      await HapticFeedback.selectionClick();
    }
    notifyListeners();
  }

  Future<void> setReduceMotionEnabled(bool value) async {
    reduceMotionEnabled = value;
    await storage.setBool('reduce_motion_enabled', value);
    notifyListeners();
  }

  void setSystemReduceMotion(bool value) {
    if (systemReduceMotion == value) return;
    systemReduceMotion = value;
    notifyListeners();
  }

  Future<void> hapticSelection() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.selectionClick();
  }

  Future<void> hapticLight() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.lightImpact();
  }

  Future<void> hapticMedium() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.mediumImpact();
  }

  Future<void> hapticHeavy() async {
    if (!hapticsEnabled) return;
    await HapticFeedback.heavyImpact();
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
    if (error == null && account.signedIn) {
      await _reconcileSocialOwnerAfterSignIn();
      await syncCloudProgress();
      if (socialEnabled) await syncSocialProfile();
    }
    notifyListeners();
    return error;
  }

  Future<String?> signInWithApple() async {
    final error = await account.signInWithApple();
    if (error == null && account.signedIn) {
      await _reconcileSocialOwnerAfterSignIn();
      await syncCloudProgress();
      if (socialEnabled) await syncSocialProfile();
    }
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
    if (error == null) {
      cloudStatusMessage = '';
      socialEnabled = false;
      friendCode = '';
      socialUsername = '';
      _socialOwnerUid = '';
      await storage.setBool('social_enabled', false);
      await storage.setString('social_friend_code', '');
      await storage.setString('social_username', '');
      await storage.setString('social_owner_uid', '');
    }
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
          bestDailyPuzzleStreak = max(
            bestDailyPuzzleStreak,
            (cloud['bestDailyPuzzleStreak'] as num?)?.toInt() ?? 0,
          );
          bestCombo = max(
            bestCombo,
            (cloud['bestCombo'] as num?)?.toInt() ?? 0,
          );
          perfectConquests = max(
            perfectConquests,
            (cloud['perfectConquests'] as num?)?.toInt() ?? 0,
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
          await storage.setInt(
            'best_daily_puzzle_streak',
            bestDailyPuzzleStreak,
          );
          await storage.setInt('best_combo', bestCombo);
          await storage.setInt('perfect_conquests', perfectConquests);
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
    'bestDailyPuzzleStreak': bestDailyPuzzleStreak,
    'bestCombo': bestCombo,
    'perfectConquests': perfectConquests,
    'crownFragments': crownFragments,
  };

  void _scheduleCloudSync() {
    if (!account.signedIn) return;
    _cloudSyncTimer?.cancel();
    _cloudSyncTimer = Timer(const Duration(seconds: 2), () {
      unawaited(syncCloudProgress());
    });
  }

  Future<void> _loadCompetitionState() async {
    final now = DateTime.now();
    competitionWeekKey = CompetitionPeriod.weekKey(now);
    competitionSeasonKey = CompetitionPeriod.seasonKey(now);
    final storedWeek = await storage.getString('competition_week_key');
    final storedSeason = await storage.getString('competition_season_key');
    weeklyScore = storedWeek == competitionWeekKey
        ? await storage.getInt('competition_weekly_score', 0)
        : 0;
    seasonScore = storedSeason == competitionSeasonKey
        ? await storage.getInt('competition_season_score', 0)
        : 0;
    socialEnabled = await storage.getBool('social_enabled', false);
    friendCode = await storage.getString('social_friend_code') ?? '';
    socialUsername = await storage.getString('social_username') ?? '';
    _socialOwnerUid = await storage.getString('social_owner_uid') ?? '';
    await _persistCompetitionState();
  }

  Future<void> _ensureCompetitionPeriods() async {
    final now = DateTime.now();
    final newWeek = CompetitionPeriod.weekKey(now);
    final newSeason = CompetitionPeriod.seasonKey(now);
    var changed = false;
    if (competitionWeekKey != newWeek) {
      competitionWeekKey = newWeek;
      weeklyScore = 0;
      changed = true;
    }
    if (competitionSeasonKey != newSeason) {
      competitionSeasonKey = newSeason;
      seasonScore = 0;
      changed = true;
    }
    if (changed) await _persistCompetitionState();
  }

  Future<void> _persistCompetitionState() async {
    await storage.setString('competition_week_key', competitionWeekKey);
    await storage.setString('competition_season_key', competitionSeasonKey);
    await storage.setInt('competition_weekly_score', weeklyScore);
    await storage.setInt('competition_season_score', seasonScore);
  }

  Future<void> _reconcileSocialOwnerAfterSignIn() async {
    if (!account.signedIn) return;
    final currentUid = account.uid;
    if (_socialOwnerUid.isEmpty) return;
    if (_socialOwnerUid == currentUid) return;

    // Aynı cihazda başka hesaba geçilirse önceki oyuncunun haftalık/seasonal
    // puanı yeni hesaba taşınmaz.
    weeklyScore = 0;
    seasonScore = 0;
    socialEnabled = false;
    friendCode = '';
    socialUsername = '';
    _socialOwnerUid = '';
    await _persistCompetitionState();
    await storage.setBool('social_enabled', false);
    await storage.setString('social_friend_code', '');
    await storage.setString('social_username', '');
    await storage.setString('social_owner_uid', '');
  }

  Future<String> resolveSocialUsername() async {
    if (!account.signedIn) return '';
    if (_socialOwnerUid == account.uid && socialUsername.isNotEmpty) {
      return socialUsername;
    }
    final remote = await account.loadSocialUsername();
    if (remote == null || remote.isEmpty) return '';
    socialUsername = remote;
    _socialOwnerUid = account.uid;
    await storage.setString('social_username', socialUsername);
    await storage.setString('social_owner_uid', _socialOwnerUid);
    notifyListeners();
    return socialUsername;
  }

  Future<String?> joinSocialCompetition({String? username}) async {
    if (!account.signedIn) {
      return 'Haftalık lige katılmak için hesabınla giriş yapmalısın.';
    }
    await _ensureCompetitionPeriods();

    final usernameResult = await account.ensureSocialUsername(
      requestedUsername: username,
    );
    if (!usernameResult.success) return usernameResult.error;

    final currentUid = account.uid;
    if (_socialOwnerUid.isNotEmpty && _socialOwnerUid != currentUid) {
      weeklyScore = 0;
      seasonScore = 0;
      friendCode = '';
    }
    _socialOwnerUid = currentUid;
    socialUsername = usernameResult.username!;
    socialEnabled = true;
    await storage.setString('social_owner_uid', currentUid);
    await storage.setString('social_username', socialUsername);
    await storage.setBool('social_enabled', true);
    await _persistCompetitionState();

    final synced = await syncSocialProfile();
    if (!synced) {
      // Benzersiz Fatih adı sunucuda başarıyla rezerve edildiyse kullanıcıdan
      // tekrar ad istemeyiz. Profil senkronu geçici olarak başarısız olsa bile
      // skor cihazda kalır ve sonraki yenilemede yeniden gönderilir.
      socialStatusMessage = 'Fatih adın kaydedildi • Lig senkronu bekliyor';
    }
    notifyListeners();
    return null;
  }

  Future<String?> leaveSocialCompetition() async {
    if (account.signedIn) {
      final error = await account.leaveSocialCompetition();
      if (error != null) return error;
    }
    socialEnabled = false;
    friendCode = '';
    await storage.setBool('social_enabled', false);
    await storage.setString('social_friend_code', '');
    socialStatusMessage = 'Sosyal sıralamadan ayrıldın.';
    notifyListeners();
    return null;
  }

  Future<bool> syncSocialProfile() async {
    if (!socialEnabled || !account.signedIn || socialSyncing) return false;
    await _ensureCompetitionPeriods();
    if (socialUsername.isEmpty) {
      final remoteUsername = await account.loadSocialUsername();
      if (remoteUsername == null || remoteUsername.isEmpty) {
        socialStatusMessage = 'Lige devam etmek için Fatih adını seç';
        notifyListeners();
        return false;
      }
      socialUsername = remoteUsername;
      _socialOwnerUid = account.uid;
      await storage.setString('social_username', socialUsername);
      await storage.setString('social_owner_uid', _socialOwnerUid);
    }
    socialSyncing = true;
    notifyListeners();
    try {
      final result = await account.syncSocialProfile(
        weeklyScore: weeklyScore,
        seasonScore: seasonScore,
        weekKey: competitionWeekKey,
        seasonKey: competitionSeasonKey,
        levelNumber: displayLevel,
        perfectConquests: perfectConquests,
      );
      if (result == null || result.friendCode.isEmpty) {
        socialStatusMessage = 'Lig senkronu bekliyor';
        return false;
      }
      friendCode = result.friendCode;
      weeklyScore = max(weeklyScore, result.weeklyScore);
      seasonScore = max(seasonScore, result.seasonScore);
      await _persistCompetitionState();
      await storage.setString('social_friend_code', friendCode);
      socialStatusMessage = 'Lig puanın güncel';
      return true;
    } finally {
      socialSyncing = false;
      notifyListeners();
    }
  }

  Future<List<LeaderboardEntry>> loadWeeklyLeaderboard() async {
    await _ensureCompetitionPeriods();
    if (socialEnabled) await syncSocialProfile();
    return account.loadWeeklyLeaderboard(competitionWeekKey);
  }

  Future<List<LeaderboardEntry>> loadSeasonLeaderboard() async {
    await _ensureCompetitionPeriods();
    if (socialEnabled) await syncSocialProfile();
    return account.loadSeasonLeaderboard(competitionSeasonKey);
  }

  Future<List<LeaderboardEntry>> loadFriendLeaderboard() async {
    await _ensureCompetitionPeriods();
    if (socialEnabled) await syncSocialProfile();
    return account.loadFriendLeaderboard(competitionWeekKey);
  }

  Future<String?> addFriendByCode(String code) async {
    if (!socialEnabled) return 'Önce haftalık lige katılmalısın.';
    return account.addFriendByCode(code);
  }

  Future<void> removeFriend(String uid) => account.removeFriend(uid);

  Future<String?> reportPlayer(
    LeaderboardEntry entry,
    ModerationReportReason reason,
  ) => account.reportUser(
    reportedUid: entry.uid,
    reportedDisplayName: entry.displayName,
    reason: reason,
  );

  Future<String?> blockPlayer(LeaderboardEntry entry) => account.blockUser(
    blockedUid: entry.uid,
    blockedDisplayName: entry.displayName,
  );

  Future<List<BlockedPlayer>> loadBlockedPlayers() =>
      account.loadBlockedPlayers();

  Future<void> unblockPlayer(String uid) => account.unblockUser(uid);

  Future<void> _awardDailyCompetition() async {
    await _ensureCompetitionPeriods();
    final lastDate = await storage.getString('competition_daily_scored_date');
    if (lastDate == dailyDateKey) return;

    final plan = <String, dynamic>{
      'date': dailyDateKey,
      'week_key': competitionWeekKey,
      'season_key': competitionSeasonKey,
      'weekly_score': weeklyScore + CompetitionScoring.dailyWin,
      'season_score': seasonScore + CompetitionScoring.dailyWin,
    };
    await storage.setString(_pendingDailyCompetitionKey, jsonEncode(plan));
    await _applyDailyCompetitionAward(plan);
    await storage.setString(_pendingDailyCompetitionKey, '');
    _scheduleSocialSync();
  }

  Future<void> _recoverPendingDailyCompetitionAward() async {
    final raw = await storage.getString(_pendingDailyCompetitionKey);
    if (raw == null || raw.trim().isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        await _applyDailyCompetitionAward(decoded);
      }
    } catch (_) {
      // Bozuk sosyal journal oyun açılışını engellemez.
    }
    await storage.setString(_pendingDailyCompetitionKey, '');
  }

  Future<void> _applyDailyCompetitionAward(Map<String, dynamic> plan) async {
    final date = plan['date'] as String? ?? '';
    if (date.isEmpty) return;
    final lastDate = await storage.getString('competition_daily_scored_date');
    if (lastDate == date) return;
    competitionWeekKey = plan['week_key'] as String? ?? competitionWeekKey;
    competitionSeasonKey =
        plan['season_key'] as String? ?? competitionSeasonKey;
    weeklyScore = (plan['weekly_score'] as num?)?.toInt() ?? weeklyScore;
    seasonScore = (plan['season_score'] as num?)?.toInt() ?? seasonScore;
    await _persistCompetitionState();
    await storage.setString('competition_daily_scored_date', date);
  }

  void _scheduleSocialSync() {
    if (!socialEnabled || !account.signedIn) return;
    _socialSyncTimer?.cancel();
    _socialSyncTimer = Timer(const Duration(seconds: 2), () {
      unawaited(syncSocialProfile());
    });
  }

  @override
  void dispose() {
    _cloudSyncTimer?.cancel();
    _socialSyncTimer?.cancel();
    _heartTicker?.cancel();
    _comboExpiryTimer?.cancel();
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

class _LevelCompletionPlan {
  const _LevelCompletionPlan({
    required this.completedLevelNumber,
    required this.nextLevelNumber,
    required this.nextLevelsCompleted,
    required this.nextCoins,
    required this.nextHearts,
    required this.nextFreeHints,
    required this.nextCrownFragments,
    required this.nextPerfectConquests,
    required this.wasPerfect,
    required this.missionDateKey,
    required this.missions,
    this.socialWeekKey,
    this.socialSeasonKey,
    this.nextWeeklyScore,
    this.nextSeasonScore,
  });

  final int completedLevelNumber;
  final int nextLevelNumber;
  final int nextLevelsCompleted;
  final int nextCoins;
  final int nextHearts;
  final int nextFreeHints;
  final int nextCrownFragments;
  final int nextPerfectConquests;
  final bool wasPerfect;
  final String missionDateKey;
  final List<DailyMission> missions;
  final String? socialWeekKey;
  final String? socialSeasonKey;
  final int? nextWeeklyScore;
  final int? nextSeasonScore;

  Map<String, Object?> toJson() => {
    'completed_level_number': completedLevelNumber,
    'next_level_number': nextLevelNumber,
    'next_levels_completed': nextLevelsCompleted,
    'next_coins': nextCoins,
    'next_hearts': nextHearts,
    'next_free_hints': nextFreeHints,
    'next_crown_fragments': nextCrownFragments,
    'next_perfect_conquests': nextPerfectConquests,
    'was_perfect': wasPerfect,
    'mission_date_key': missionDateKey,
    'missions': missions.map((mission) => mission.toJson()).toList(),
    'social_week_key': socialWeekKey,
    'social_season_key': socialSeasonKey,
    'next_weekly_score': nextWeeklyScore,
    'next_season_score': nextSeasonScore,
  };

  factory _LevelCompletionPlan.fromJson(Map<String, dynamic> json) {
    final rawMissions = json['missions'];
    final missions = rawMissions is List
        ? rawMissions
              .whereType<Map>()
              .map(
                (item) => DailyMission.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <DailyMission>[];

    int readInt(String key) => (json[key] as num).toInt();

    return _LevelCompletionPlan(
      completedLevelNumber: readInt('completed_level_number'),
      nextLevelNumber: readInt('next_level_number'),
      nextLevelsCompleted: readInt('next_levels_completed'),
      nextCoins: readInt('next_coins'),
      nextHearts: readInt('next_hearts'),
      nextFreeHints: readInt('next_free_hints'),
      nextCrownFragments: readInt('next_crown_fragments'),
      nextPerfectConquests: readInt('next_perfect_conquests'),
      wasPerfect: json['was_perfect'] as bool? ?? false,
      missionDateKey: json['mission_date_key'] as String? ?? '',
      missions: missions,
      socialWeekKey: json['social_week_key'] as String?,
      socialSeasonKey: json['social_season_key'] as String?,
      nextWeeklyScore: (json['next_weekly_score'] as num?)?.toInt(),
      nextSeasonScore: (json['next_season_score'] as num?)?.toInt(),
    );
  }
}

class LevelMilestoneReward {
  const LevelMilestoneReward({
    required this.level,
    required this.title,
    required this.message,
    this.coins = 0,
    this.hearts = 0,
    this.freeHints = 0,
    this.crownFragments = 0,
  });

  final int level;
  final String title;
  final String message;
  final int coins;
  final int hearts;
  final int freeHints;
  final int crownFragments;
}

enum ConquestHintType { revealLetter, firstLetter, revealTwoLetters }

class HintResult {
  const HintResult(
    this.used,
    this.usedFreeHint, {
    this.spentCoins = 0,
    this.revealedCount = 0,
    this.message = '',
  });

  final bool used;
  final bool usedFreeHint;
  final int spentCoins;
  final int revealedCount;
  final String message;
}

class PerfectConquestReward {
  const PerfectConquestReward({required this.coins, required this.message});

  final int coins;
  final String message;
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
    required this.word,
    required this.bonusTreasureOpened,
  });

  final String message;
  final bool isTarget;
  final bool isBonus;
  final bool completed;
  final bool lostHeart;
  final bool noHearts;
  final bool isDuplicate;
  final String comboMessage;
  final String word;
  final bool bonusTreasureOpened;

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
    word: word,
    bonusTreasureOpened: false,
  );

  factory ConquestResult.bonus(
    String word, {
    required String comboMessage,
    bool bonusTreasureOpened = false,
  }) => ConquestResult._(
    message: bonusTreasureOpened
        ? '${TurkishText.upper(word)} bonus! Bonus Hazinesi açıldı: +20 altın 🎁'
        : '${TurkishText.upper(word)} bonus! +1 altın',
    isTarget: false,
    isBonus: true,
    completed: false,
    lostHeart: false,
    noHearts: false,
    isDuplicate: false,
    comboMessage: comboMessage,
    word: word,
    bonusTreasureOpened: bonusTreasureOpened,
  );

  factory ConquestResult.properNameBonus(
    String word, {
    required String comboMessage,
    bool bonusTreasureOpened = false,
  }) => ConquestResult._(
    message: bonusTreasureOpened
        ? '${TurkishText.upper(word)} özel isim bonusu! Bonus Hazinesi: +20 altın 🎁'
        : '${TurkishText.upper(word)} özel isim bonusu! +1 altın',
    isTarget: false,
    isBonus: true,
    completed: false,
    lostHeart: false,
    noHearts: false,
    isDuplicate: false,
    comboMessage: comboMessage,
    word: word,
    bonusTreasureOpened: bonusTreasureOpened,
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
    word: word,
    bonusTreasureOpened: false,
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
        word: '',
        bonusTreasureOpened: false,
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
    word: '',
    bonusTreasureOpened: false,
  );
}
