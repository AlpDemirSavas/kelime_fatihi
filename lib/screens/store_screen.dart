import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/game_controller.dart';
import '../core/game_theme.dart';
import '../services/purchase_service.dart';
import '../widgets/animated_background.dart';
import '../widgets/game_scope.dart';
import '../widgets/glass_card.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  bool _startedMonetization = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_startedMonetization) return;
    _startedMonetization = true;
    // Mağaza hemen açılır. Reklam ve platform mağazası yalnızca bu ekrana
    // gelindiğinde arka planda hazırlanır; offline oyun akışını bloke etmez.
    unawaited(GameScope.of(context).prepareStore());
  }

  @override
  Widget build(BuildContext context) {
    final game = GameScope.of(context);
    final store = game.purchases;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Fetih Mağazası'),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 72, 20, 28),
            children: [
              GlassCard(
                child: Row(
                  children: [
                    const Icon(
                      Icons.favorite_rounded,
                      color: GameTheme.danger,
                      size: 38,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Can Hazinesi',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                            ),
                          ),
                          Text(
                            'Şu an ${game.hearts} canın ve ${game.coins} altının var.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .65),
                            ),
                          ),
                          if (game.hearts <
                              GameController.maxNaturalHearts) ...[
                            const SizedBox(height: 3),
                            Text(
                              'Doğal yenilenme: ${game.nextHeartLabel}',
                              style: const TextStyle(
                                color: GameTheme.cyan,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: GameTheme.gold.withValues(alpha: .12),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: GameTheme.danger,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Altınla Can Al',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '50 altın harca, +1 can kazan.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .6),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: () async {
                        final bought = await game.buyHeartWithCoins();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              bought
                                  ? '+1 can aldın! 50 altın harcandı.'
                                  : 'Yeterli altının yok. 1 can için 50 altın gerekiyor.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.monetization_on_rounded),
                      label: const Text('50'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Pack(
                title: 'Gezgin Paketi',
                hearts: 5,
                price: store.priceFor(PurchaseService.productHeart5, '₺29,99'),
                onBuy: () => store.buy(PurchaseService.productHeart5),
              ),
              const SizedBox(height: 12),
              _Pack(
                title: 'Fatih Paketi',
                hearts: 20,
                price: store.priceFor(PurchaseService.productHeart20, '₺79,99'),
                popular: true,
                onBuy: () => store.buy(PurchaseService.productHeart20),
              ),
              const SizedBox(height: 12),
              _Pack(
                title: 'İmparator Paketi',
                hearts: 50,
                price: store.priceFor(
                  PurchaseService.productHeart50,
                  '₺149,99',
                ),
                onBuy: () => store.buy(PurchaseService.productHeart50),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  children: [
                    Icon(
                      game.isAdFree
                          ? Icons.verified_rounded
                          : Icons.block_rounded,
                      color: game.isAdFree ? GameTheme.mint : GameTheme.gold,
                      size: 36,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      game.isAdFree
                          ? 'Reklamsız Sürüm Aktif'
                          : 'Reklamsız Sürüm',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 19,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      game.isAdFree
                          ? 'Bölüm sonu zorunlu reklamları artık gösterilmez. İstersen ödüllü reklamı yine kullanabilirsin.'
                          : 'Tek seferlik satın al. Bölüm sonu zorunlu reklamları kalıcı olarak kaldır.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!game.isAdFree)
                      FilledButton.icon(
                        onPressed: () =>
                            store.buy(PurchaseService.productAdFree),
                        icon: const Icon(Icons.workspace_premium_rounded),
                        label: Text(
                          store.priceFor(
                            PurchaseService.productAdFree,
                            '₺149,99',
                          ),
                        ),
                      ),
                    TextButton.icon(
                      onPressed: () async {
                        await game.restorePurchases();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Mağaza satın almaları geri yükleme isteği gönderildi.',
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('SATIN ALMALARI GERİ YÜKLE'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GlassCard(
                child: Column(
                  children: [
                    const Icon(
                      Icons.ondemand_video_rounded,
                      color: GameTheme.cyan,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Ücretsiz Can',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ödüllü reklam izle ve +1 can kazan.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: .65),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        final earned = await game.watchAdForHeart();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                earned
                                    ? '+1 can eklendi!'
                                    : 'Reklam henüz hazır değil. Biraz sonra tekrar dene.',
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('REKLAM İZLE'),
                    ),
                  ],
                ),
              ),
              if (kDebugMode) ...[
                const SizedBox(height: 16),
                Text(
                  'Geliştirici modu: Store ürünleri tanımlı değilse paket butonları satın almayı simüle eder.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: .45),
                  ),
                ),
              ],
              if (store.errorMessage != null) ...[
                const SizedBox(height: 10),
                GlassCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cloud_off_rounded,
                        color: GameTheme.gold,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          store.errorMessage!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .72),
                            fontSize: 12,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: store.loading ? null : store.reloadProducts,
                        child: const Text('TEKRAR DENE'),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Pack extends StatelessWidget {
  const _Pack({
    required this.title,
    required this.hearts,
    required this.price,
    required this.onBuy,
    this.popular = false,
  });
  final String title;
  final int hearts;
  final String price;
  final VoidCallback onBuy;
  final bool popular;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: GameTheme.danger.withValues(alpha: .12),
            ),
            alignment: Alignment.center,
            child: Text(
              '❤\n$hearts',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: GameTheme.danger,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                        ),
                      ),
                    ),
                    if (popular) ...[
                      const SizedBox(width: 7),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: GameTheme.gold,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'POPÜLER',
                          style: TextStyle(
                            color: Color(0xFF201800),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '$hearts ekstra can',
                  style: TextStyle(color: Colors.white.withValues(alpha: .6)),
                ),
              ],
            ),
          ),
          FilledButton(onPressed: onBuy, child: Text(price)),
        ],
      ),
    );
  }
}
