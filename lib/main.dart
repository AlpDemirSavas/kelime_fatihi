import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'controllers/game_controller.dart';
import 'core/game_theme.dart';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'services/account_service.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/dictionary_service.dart';
import 'services/purchase_service.dart';
import 'services/storage_service.dart';
import 'widgets/game_scope.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  var firebaseReady = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseReady = true;
  } catch (_) {
    // Firebase yapılandırılmadan da oyun tamamen offline/local çalışır.
    // `flutterfire configure` tamamlandığında bu blok otomatik olarak gerçek
    // Firebase seçenekleriyle çalışmaya başlar.
  }

  final controller = GameController(
    dictionary: DictionaryService(),
    storage: StorageService(),
    ads: AdService(),
    purchases: PurchaseService(),
    audio: AudioService(),
    account: AccountService(firebaseReady: firebaseReady),
  );
  runApp(KelimeFatihiApp(controller: controller));
  controller.initialize();
}

class KelimeFatihiApp extends StatefulWidget {
  const KelimeFatihiApp({super.key, required this.controller});
  final GameController controller;

  @override
  State<KelimeFatihiApp> createState() => _KelimeFatihiAppState();
}

class _KelimeFatihiAppState extends State<KelimeFatihiApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _syncSystemReduceMotion();
  }

  @override
  void didChangeAccessibilityFeatures() {
    _syncSystemReduceMotion();
  }

  void _syncSystemReduceMotion() {
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    widget.controller.setSystemReduceMotion(
      features.reduceMotion || features.disableAnimations,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.ads.dispose();
    widget.controller.purchases.dispose();
    widget.controller.account.dispose();
    unawaited(widget.controller.audio.dispose());
    widget.controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope(
      controller: widget.controller,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Kelime Fatihi',
        theme: GameTheme.build(),
        builder: (context, child) {
          final game = GameScope.of(context);
          final media = MediaQuery.of(context);
          final reduceMotion =
              game.effectiveReduceMotion || media.disableAnimations;
          return MediaQuery(
            data: media.copyWith(disableAnimations: reduceMotion),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const HomeScreen(),
      ),
    );
  }
}
