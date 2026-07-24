import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitial;
  RewardedAd? _rewarded;
  bool _initialized = false;
  bool _interstitialLoading = false;
  Future<void>? _initializeFuture;
  Future<void>? _rewardedLoadFuture;
  bool privacyOptionsRequired = false;

  static const String _androidInterstitialLive =
      String.fromEnvironment('ADMOB_ANDROID_INTERSTITIAL');
  static const String _iosInterstitialLive =
      String.fromEnvironment('ADMOB_IOS_INTERSTITIAL');
  static const String _androidRewardedLive =
      String.fromEnvironment('ADMOB_ANDROID_REWARDED');
  static const String _iosRewardedLive =
      String.fromEnvironment('ADMOB_IOS_REWARDED');

  static String get _interstitialId {
    if (!kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/1033173712'
          : 'ca-app-pub-3940256099942544/4411468910';
    }
    return Platform.isAndroid ? _androidInterstitialLive : _iosInterstitialLive;
  }

  static String get _rewardedId {
    if (!kReleaseMode) {
      return Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/5224354917'
          : 'ca-app-pub-3940256099942544/1712485313';
    }
    return Platform.isAndroid ? _androidRewardedLive : _iosRewardedLive;
  }

  Future<void> initialize() {
    if (_initialized || kIsWeb) return Future<void>.value();
    if (!Platform.isAndroid && !Platform.isIOS) return Future<void>.value();

    return _initializeFuture ??= _doInitialize().whenComplete(() {
      _initializeFuture = null;
    });
  }

  Future<void> _doInitialize() async {
    await _gatherConsent();
    final canRequestAds = await ConsentInformation.instance.canRequestAds();
    privacyOptionsRequired =
        await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() ==
            PrivacyOptionsRequirementStatus.required;
    if (!canRequestAds) return;

    await MobileAds.instance.initialize();
    _initialized = true;
    loadInterstitial();
    // Rewarded reklam yalnızca mağaza/can ihtiyacında gerçekten beklenir.
    unawaited(loadRewarded());
  }

  Future<void> _gatherConsent() async {
    final completer = Completer<void>();
    final params = ConsentRequestParameters();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) {
          if (!completer.isCompleted) completer.complete();
        });
      },
      (_) {
        if (!completer.isCompleted) completer.complete();
      },
    );
    await completer.future;
  }

  void showPrivacyOptions() {
    ConsentForm.showPrivacyOptionsForm((_) {});
  }

  void loadInterstitial() {
    if (!_initialized || _interstitial != null || _interstitialLoading) return;
    if (_interstitialId.isEmpty) return;
    _interstitialLoading = true;
    InterstitialAd.load(
      adUnitId: _interstitialId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialLoading = false;
          _interstitial = ad;
        },
        onAdFailedToLoad: (_) {
          _interstitialLoading = false;
          _interstitial = null;
        },
      ),
    );
  }

  void showInterstitial() {
    unawaited(showInterstitialIfReady());
  }

  Future<bool> showInterstitialIfReady() async {
    final ad = _interstitial;
    if (ad == null) {
      loadInterstitial();
      return false;
    }

    _interstitial = null;
    final completer = Completer<bool>();
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        loadInterstitial();
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show();
    return completer.future;
  }

  Future<void> loadRewarded() {
    if (!_initialized || _rewarded != null) return Future<void>.value();
    return _rewardedLoadFuture ??= _loadRewardedInternal().whenComplete(() {
      _rewardedLoadFuture = null;
    });
  }

  Future<void> _loadRewardedInternal() async {
    if (_rewardedId.isEmpty) return;
    final completer = Completer<void>();
    RewardedAd.load(
      adUnitId: _rewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewarded = ad;
          if (!completer.isCompleted) completer.complete();
        },
        onAdFailedToLoad: (_) {
          _rewarded = null;
          if (!completer.isCompleted) completer.complete();
        },
      ),
    );
    await completer.future;
  }

  Future<bool> showRewarded() async {
    await initialize();
    if (!_initialized) return false;
    if (_rewarded == null) await loadRewarded();

    final ad = _rewarded;
    if (ad == null) return false;

    _rewarded = null;
    final completer = Completer<bool>();
    var earned = false;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete(earned);
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        unawaited(loadRewarded());
        if (!completer.isCompleted) completer.complete(false);
      },
    );
    ad.show(onUserEarnedReward: (_, __) => earned = true);
    return completer.future;
  }

  void dispose() {
    _interstitial?.dispose();
    _rewarded?.dispose();
  }
}
