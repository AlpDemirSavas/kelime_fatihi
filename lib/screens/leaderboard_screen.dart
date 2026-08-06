import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../models/competition.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import 'account_screen.dart';

enum _PlayerAction { report, block, removeFriend }

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool _loading = false;
  List<LeaderboardEntry> _weekly = const [];
  List<LeaderboardEntry> _season = const [];
  List<LeaderboardEntry> _friends = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    final game = GameScope.of(context);
    if (!game.signedIn ||
        !game.socialEnabled ||
        game.socialUsername.isEmpty) {
      return;
    }
    setState(() => _loading = true);
    final results = await Future.wait([
      game.loadWeeklyLeaderboard(),
      game.loadSeasonLeaderboard(),
      game.loadFriendLeaderboard(),
    ]);
    if (!mounted) return;
    setState(() {
      _weekly = results[0];
      _season = results[1];
      _friends = results[2];
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final league = game.currentLeague;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Fatihler Ligi'),
        actions: [
          if (game.signedIn && game.socialEnabled)
            IconButton(
              tooltip: 'Engellenen oyuncular',
              onPressed: () => _showBlockedPlayers(game),
              icon: const Icon(Icons.shield_outlined),
            ),
          if (game.signedIn && game.socialEnabled)
            IconButton(
              tooltip: 'Yenile',
              onPressed: _loading ? null : _refresh,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: GameTheme.gold,
        child: SafeArea(
          child: !game.signedIn
              ? _SignedOutState(
                  onSignIn: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                )
              : !game.socialEnabled || game.socialUsername.isEmpty
              ? _JoinState(onJoin: () => _join(game))
              : DefaultTabController(
                  length: 3,
                  child: Column(
                    children: [
                      const SizedBox(height: 58),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _LeagueHero(
                          league: league,
                          username: game.socialUsername,
                          seasonScore: game.seasonScore,
                          weeklyScore: game.weeklyScore,
                          progress: game.leagueProgress,
                          friendCode: game.friendCode,
                          syncing: game.socialSyncing,
                          onCopyCode: game.friendCode.isEmpty
                              ? null
                              : () => _copyCode(game.friendCode),
                          onAddFriend: () => _showAddFriend(game),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .07),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .1),
                            ),
                          ),
                          child: const TabBar(
                            dividerColor: Colors.transparent,
                            tabs: [
                              Tab(text: 'Haftalık'),
                              Tab(text: 'Sezon'),
                              Tab(text: 'Arkadaşlar'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: _loading
                            ? const Center(child: CircularProgressIndicator())
                            : TabBarView(
                                children: [
                                  _RankingList(
                                    entries: _weekly,
                                    currentUid: game.account.uid,
                                    scoreOf: (entry) => entry.weeklyScore,
                                    emptyText:
                                        'Bu haftanın sıralaması henüz oluşmadı.',
                                    onReport: (entry) =>
                                        _showReportDialog(game, entry),
                                    onBlock: (entry) =>
                                        _confirmBlock(game, entry),
                                  ),
                                  _RankingList(
                                    entries: _season,
                                    currentUid: game.account.uid,
                                    scoreOf: (entry) => entry.seasonScore,
                                    showLeague: true,
                                    emptyText:
                                        'Bu sezonun sıralaması henüz oluşmadı.',
                                    onReport: (entry) =>
                                        _showReportDialog(game, entry),
                                    onBlock: (entry) =>
                                        _confirmBlock(game, entry),
                                  ),
                                  _RankingList(
                                    entries: _friends,
                                    currentUid: game.account.uid,
                                    scoreOf: (entry) => entry.weeklyScore,
                                    emptyText:
                                        'Arkadaş koduyla oyuncu ekleyip haftalık skorlarınızı karşılaştır.',
                                    onReport: (entry) =>
                                        _showReportDialog(game, entry),
                                    onBlock: (entry) =>
                                        _confirmBlock(game, entry),
                                    onRemove: (uid) async {
                                      await game.removeFriend(uid);
                                      await _refresh();
                                    },
                                  ),
                                ],
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 6, 18, 16),
                        child: Text(
                          'Puan: bölüm +${CompetitionScoring.levelBase} • bonus kelime +${CompetitionScoring.bonusWord} • kusursuz fetih +${CompetitionScoring.perfectConquest} • Günün Kelimesi +${CompetitionScoring.dailyWin}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .46),
                            fontSize: 10.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _join(GameController game) async {
    setState(() => _loading = true);
    final existing = await game.resolveSocialUsername();
    if (!mounted) return;
    setState(() => _loading = false);

    if (existing.isNotEmpty) {
      setState(() => _loading = true);
      final error = await game.joinSocialCompetition();
      if (!mounted) return;
      setState(() => _loading = false);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
        return;
      }
      await _refresh();
      return;
    }

    final joined = await _showUsernameDialog(game);
    if (!mounted || !joined) return;
    await _refresh();
  }

  Future<bool> _showUsernameDialog(GameController game) async {
    final controller = TextEditingController(
      text: game.account.suggestedSocialUsername,
    );
    String? errorText;
    var submitting = false;

    final joined = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> submit() async {
            if (submitting) return;
            final candidate = UsernameRules.sanitizeDisplay(controller.text);
            final validation = UsernameRules.validate(candidate);
            if (validation != null) {
              setDialogState(() => errorText = validation);
              return;
            }

            setDialogState(() {
              submitting = true;
              errorText = null;
            });
            final error = await game.joinSocialCompetition(username: candidate);
            if (!dialogContext.mounted) return;
            if (error != null) {
              setDialogState(() {
                submitting = false;
                errorText = error;
              });
              return;
            }
            Navigator.of(dialogContext).pop(true);
          }

          return AlertDialog(
            title: const Text('Fatih Adını Seç'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bu ad liglerde diğer oyunculara gösterilir ve hesabın için bir kez seçilir. E-posta adresin gösterilmez.',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  autofocus: true,
                  enabled: !submitting,
                  maxLength: UsernameRules.maxLength,
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(UsernameRules.maxLength),
                    FilteringTextInputFormatter.allow(
                      RegExp(r'[A-Za-z0-9_ ÇĞİÖŞÜçğıöşü]'),
                    ),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Fatih adı',
                    hintText: 'Örn. AlpFatih',
                    helperText: '3–18 karakter • Benzersiz olmalı',
                    errorText: errorText,
                  ),
                  onChanged: (_) {
                    if (errorText != null) {
                      setDialogState(() => errorText = null);
                    }
                  },
                  onSubmitted: (_) => submit(),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: submitting
                    ? null
                    : () => Navigator.of(dialogContext).pop(false),
                child: const Text('VAZGEÇ'),
              ),
              FilledButton(
                onPressed: submitting ? null : submit,
                child: submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('ADI AL'),
              ),
            ],
          );
        },
      ),
    );
    controller.dispose();
    return joined == true;
  }

  Future<void> _showReportDialog(
    GameController game,
    LeaderboardEntry entry,
  ) async {
    final reason = await showDialog<ModerationReportReason>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        title: Text('${entry.displayName} kullanıcısını şikâyet et'),
        children: [
          for (final item in ModerationReportReason.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(dialogContext, item),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(item.title),
              ),
            ),
          const Divider(),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
        ],
      ),
    );
    if (reason == null) return;

    final error = await game.reportPlayer(entry, reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error ?? 'Şikâyetin alındı. Teşekkürler.',
        ),
      ),
    );
  }

  Future<void> _confirmBlock(
    GameController game,
    LeaderboardEntry entry,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kullanıcıyı Engelle'),
        content: Text(
          '${entry.displayName} sıralamalardan ve arkadaş görünümünden gizlenecek. '
          'İstersen daha sonra kalkan simgesinden engeli kaldırabilirsin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('ENGELLE'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await game.blockPlayer(entry);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '${entry.displayName} engellendi.'),
      ),
    );
    if (error == null) await _refresh();
  }

  Future<void> _showBlockedPlayers(GameController game) async {
    final blocked = await game.loadBlockedPlayers();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Engellenen Oyuncular'),
        content: SizedBox(
          width: 420,
          child: blocked.isEmpty
              ? const Text('Engellediğin oyuncu yok.')
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: blocked.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final player = blocked[index];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.block_rounded),
                      title: Text(player.displayName),
                      trailing: TextButton(
                        onPressed: () async {
                          await game.unblockPlayer(player.uid);
                          if (!dialogContext.mounted) return;
                          Navigator.pop(dialogContext);
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${player.displayName} için engel kaldırıldı.',
                              ),
                            ),
                          );
                          await _refresh();
                        },
                        child: const Text('ENGELİ KALDIR'),
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('KAPAT'),
          ),
        ],
      ),
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Arkadaş kodu kopyalandı.')),
    );
  }

  Future<void> _showAddFriend(GameController game) async {
    final controller = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Arkadaş Ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Arkadaş kodu',
            hintText: 'KF-XXXXXXXX',
          ),
          onSubmitted: (value) => Navigator.pop(dialogContext, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('VAZGEÇ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('EKLE'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (code == null || code.trim().isEmpty) return;
    final error = await game.addFriendByCode(code);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error ?? 'Arkadaş listeye eklendi.')),
    );
    if (error == null) await _refresh();
  }
}

class _SignedOutState extends StatelessWidget {
  const _SignedOutState({required this.onSignIn});
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏆', style: TextStyle(fontSize: 58)),
            const SizedBox(height: 10),
            const Text(
              'Fatihler Ligi',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Haftalık sıralama, sezon ligi ve arkadaş skorları için hesabınla giriş yap.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .62)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onSignIn,
              icon: const Icon(Icons.login_rounded),
              label: const Text('HESABA GİT'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _JoinState extends StatelessWidget {
  const _JoinState({required this.onJoin});
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('👑', style: TextStyle(fontSize: 60)),
            const SizedBox(height: 10),
            const Text(
              'Lige Katıl',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'İlk katılımda bir kez benzersiz Fatih adını seçersin. Liglerde yalnız bu adın ve oyun skorun görünür; e-posta adresin paylaşılmaz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: .62)),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onJoin,
              icon: const Icon(Icons.emoji_events_rounded),
              label: const Text('FATİHLER LİGİNE KATIL'),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LeagueHero extends StatelessWidget {
  const _LeagueHero({
    required this.league,
    required this.username,
    required this.seasonScore,
    required this.weeklyScore,
    required this.progress,
    required this.friendCode,
    required this.syncing,
    required this.onCopyCode,
    required this.onAddFriend,
  });

  final LeagueTier league;
  final String username;
  final int seasonScore;
  final int weeklyScore;
  final double progress;
  final String friendCode;
  final bool syncing;
  final VoidCallback? onCopyCode;
  final VoidCallback onAddFriend;

  @override
  Widget build(BuildContext context) {
    final next = league.nextThreshold;
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: GameTheme.gold.withValues(alpha: .12),
                  border: Border.all(
                    color: GameTheme.gold.withValues(alpha: .32),
                  ),
                ),
                child: Text(league.emoji, style: const TextStyle(fontSize: 30)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${league.title} Ligi',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$username • Bu hafta $weeklyScore • Sezon $seasonScore puan',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .62),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (syncing)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            borderRadius: BorderRadius.circular(99),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              next == null
                  ? 'En yüksek ligdesin. 👑'
                  : '${next - seasonScore} puan sonra sonraki lig',
              style: TextStyle(
                color: Colors.white.withValues(alpha: .5),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCopyCode,
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  label: Text(friendCode.isEmpty ? 'Kod hazırlanıyor' : friendCode),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: 'Arkadaş ekle',
                onPressed: onAddFriend,
                icon: const Icon(Icons.person_add_alt_1_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RankingList extends StatelessWidget {
  const _RankingList({
    required this.entries,
    required this.currentUid,
    required this.scoreOf,
    required this.emptyText,
    this.showLeague = false,
    this.onReport,
    this.onBlock,
    this.onRemove,
  });

  final List<LeaderboardEntry> entries;
  final String currentUid;
  final int Function(LeaderboardEntry entry) scoreOf;
  final String emptyText;
  final bool showLeague;
  final Future<void> Function(LeaderboardEntry entry)? onReport;
  final Future<void> Function(LeaderboardEntry entry)? onBlock;
  final Future<void> Function(String uid)? onRemove;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(
            emptyText,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: .55)),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = entries[index];
        final mine = entry.uid == currentUid;
        final rank = index + 1;
        final medal = switch (rank) {
          1 => '🥇',
          2 => '🥈',
          3 => '🥉',
          _ => '#$rank',
        };
        final tier = LeagueTier.forScore(entry.seasonScore);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: mine
                ? GameTheme.cyan.withValues(alpha: .1)
                : Colors.white.withValues(alpha: .055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: mine
                  ? GameTheme.cyan.withValues(alpha: .32)
                  : Colors.white.withValues(alpha: .08),
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                child: Text(
                  medal,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: rank <= 3 ? 20 : 12,
                    fontWeight: FontWeight.w900,
                    color: Colors.white.withValues(alpha: .72),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mine ? '${entry.displayName} • SEN' : entry.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      showLeague
                          ? '${tier.emoji} ${tier.title} • Bölüm ${entry.levelNumber}'
                          : 'Bölüm ${entry.levelNumber} • Kusursuz ${entry.perfectConquests}',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .48),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${scoreOf(entry)}',
                style: const TextStyle(
                  color: GameTheme.gold,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              if (!mine && (onReport != null || onBlock != null || onRemove != null)) ...[
                const SizedBox(width: 2),
                PopupMenuButton<_PlayerAction>(
                  tooltip: 'Oyuncu seçenekleri',
                  icon: const Icon(Icons.more_vert_rounded, size: 20),
                  onSelected: (action) async {
                    switch (action) {
                      case _PlayerAction.report:
                        await onReport?.call(entry);
                        break;
                      case _PlayerAction.block:
                        await onBlock?.call(entry);
                        break;
                      case _PlayerAction.removeFriend:
                        await onRemove?.call(entry.uid);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onReport != null)
                      const PopupMenuItem(
                        value: _PlayerAction.report,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.flag_outlined),
                          title: Text('Şikâyet Et'),
                        ),
                      ),
                    if (onBlock != null)
                      const PopupMenuItem(
                        value: _PlayerAction.block,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.block_rounded),
                          title: Text('Kullanıcıyı Engelle'),
                        ),
                      ),
                    if (onRemove != null)
                      const PopupMenuItem(
                        value: _PlayerAction.removeFriend,
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.person_remove_alt_1_outlined),
                          title: Text('Arkadaşlıktan Çıkar'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
