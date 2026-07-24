import 'dart:io';

import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';
import 'privacy_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, title: const Text('Hesap ve Bulut Yedeği')),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        accent: game.currentRegion.accent,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
            children: [
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameTheme.cyan.withValues(alpha: .12),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        game.signedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                        color: game.signedIn ? GameTheme.mint : GameTheme.cyan,
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            game.signedIn ? game.accountName : 'Misafir Oyuncu',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            game.signedIn
                                ? (game.accountEmail.isEmpty ? 'Bulut yedeği açık' : game.accountEmail)
                                : 'Oyun bu cihazda kaydedilir. Hesapla giriş yaparsan seviye ve ilerleme buluta yedeklenir.',
                            style: TextStyle(color: Colors.white.withValues(alpha: .62)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (!game.account.available)
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.settings_rounded, color: GameTheme.gold),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text('Firebase yapılandırması gerekiyor', style: TextStyle(fontWeight: FontWeight.w900)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Oyun offline çalışmaya devam eder. Google/Apple girişini açmak için proje kökünde flutterfire configure adımını tamamla.',
                        style: TextStyle(color: Colors.white.withValues(alpha: .65)),
                      ),
                    ],
                  ),
                )
              else if (!game.signedIn) ...[
                _LoginButton(
                  icon: Icons.g_mobiledata_rounded,
                  label: 'Google ile giriş yap',
                  color: Colors.white,
                  foreground: const Color(0xFF111827),
                  onPressed: _busy ? null : () => _signInGoogle(game),
                ),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 10),
                  _LoginButton(
                    icon: Icons.apple_rounded,
                    label: 'Apple ile giriş yap',
                    color: Colors.white,
                    foreground: Colors.black,
                    onPressed: _busy ? null : () => _signInApple(game),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  'Giriş zorunlu değildir. Metroda veya internet yokken misafir olarak oynamaya devam edebilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: .5), fontSize: 12),
                ),
              ] else ...[
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.backup_rounded, color: GameTheme.mint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              game.cloudSyncing
                                  ? 'Bulut yedeği güncelleniyor…'
                                  : (game.cloudStatusMessage.isEmpty ? 'İlerleme yedeği hazır' : game.cloudStatusMessage),
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Seviye, fethedilen bölüm sayısı, rekorlar ve taç ilerlemesi hesabına bağlanır. Can/altın cihaz ekonomisi olarak tutulur; reklamsız satın alma mağazadan geri yüklenir.',
                        style: TextStyle(color: Colors.white.withValues(alpha: .62), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: (_busy || game.cloudSyncing) ? null : () => _sync(game),
                        icon: const Icon(Icons.sync_rounded),
                        label: const Text('ŞİMDİ YEDEKLE'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _busy ? null : () async {
                    setState(() => _busy = true);
                    await game.signOutAccount();
                    if (mounted) setState(() => _busy = false);
                  },
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Hesaptan çık'),
                ),
                const SizedBox(height: 20),
                TextButton.icon(
                  onPressed: _busy ? null : () => _confirmDelete(game),
                  icon: const Icon(Icons.delete_forever_rounded, color: GameTheme.danger),
                  label: const Text('Hesabı ve bulut yedeğini sil', style: TextStyle(color: GameTheme.danger)),
                ),
              ],
              const SizedBox(height: 18),
              TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyScreen()),
                ),
                icon: const Icon(Icons.privacy_tip_outlined),
                label: const Text('Gizlilik politikasını görüntüle'),
              ),
              if (_busy) ...[
                const SizedBox(height: 16),
                const Center(child: CircularProgressIndicator()),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInGoogle(GameController game) async {
    setState(() => _busy = true);
    final error = await game.signInWithGoogle();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _show(error);
  }

  Future<void> _signInApple(GameController game) async {
    setState(() => _busy = true);
    final error = await game.signInWithApple();
    if (!mounted) return;
    setState(() => _busy = false);
    if (error != null) _show(error);
  }

  Future<void> _sync(GameController game) async {
    setState(() => _busy = true);
    await game.syncCloudProgress();
    if (!mounted) return;
    setState(() => _busy = false);
    _show('İlerleme bulutla eşitlendi.');
  }

  Future<void> _confirmDelete(GameController game) async {
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hesabı sil?'),
        content: const Text(
          'Buluttaki Kelime Fatihi yedeğin silinir ve hesabın uygulamadan kaldırılır. Bu işlem geri alınamaz. Cihazdaki yerel oyun kaydı ayrıca kalabilir.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('VAZGEÇ')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('HESABI SİL')),
        ],
      ),
    );
    if (accepted != true || !mounted) return;

    setState(() => _busy = true);
    final error = await game.deleteAccount();
    if (!mounted) return;
    setState(() => _busy = false);
    _show(error ?? 'Hesap ve bulut yedeği silindi.');
  }

  void _show(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.foreground,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(52),
      ),
      onPressed: onPressed,
      icon: Icon(icon, size: 29),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}
