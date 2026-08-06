import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../services/ad_service.dart';

class DismissibleBannerAd extends StatefulWidget {
  const DismissibleBannerAd({
    super.key,
    required this.ads,
    required this.isAdFree,
  });

  final AdService ads;
  final bool isAdFree;

  @override
  State<DismissibleBannerAd> createState() => _DismissibleBannerAdState();
}

class _DismissibleBannerAdState extends State<DismissibleBannerAd> {
  static const int _maxLoadAttempts = 2;
  static const Duration _retryDelay = Duration(seconds: 45);

  BannerAd? _banner;
  Timer? _retryTimer;
  bool _loading = false;
  bool _dismissed = false;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant DismissibleBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isAdFree && widget.isAdFree) {
      _cancelRetry();
      _disposeBanner();
      return;
    }

    if (oldWidget.ads != widget.ads) {
      _cancelRetry();
      _disposeBanner();
      _dismissed = false;
      _loadAttempts = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted ||
        _loading ||
        _dismissed ||
        widget.isAdFree ||
        _banner != null ||
        _loadAttempts >= _maxLoadAttempts ||
        widget.ads.bannerDismissedForSession) {
      return;
    }

    _loading = true;
    _loadAttempts++;
    BannerAd? banner;
    try {
      banner = await widget.ads.loadBanner();
    } catch (_) {
      // Reklam SDK/ağ hatası oyun arayüzünü etkilememeli.
      banner = null;
    } finally {
      _loading = false;
    }

    if (!mounted ||
        _dismissed ||
        widget.isAdFree ||
        widget.ads.bannerDismissedForSession) {
      banner?.dispose();
      return;
    }

    if (banner != null) {
      _cancelRetry();
      setState(() => _banner = banner);
      return;
    }

    // İlk istekte no-fill/ağ hatası olursa yalnız bir kez gecikmeli tekrar dene.
    // Kullanıcı bannerı kapattıysa oturum boyunca yeniden istek yapılmaz.
    if (_loadAttempts < _maxLoadAttempts &&
        !widget.ads.bannerDismissedForSession) {
      _retryTimer = Timer(_retryDelay, () {
        if (mounted &&
            !_dismissed &&
            !widget.isAdFree &&
            !widget.ads.bannerDismissedForSession) {
          _load();
        }
      });
    }
  }

  void _dismiss() {
    _cancelRetry();
    widget.ads.dismissBannerForSession();
    _dismissed = true;
    _disposeBanner();
    if (mounted) setState(() {});
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
  }

  @override
  void dispose() {
    _cancelRetry();
    _disposeBanner();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banner = _banner;
    if (widget.isAdFree ||
        _dismissed ||
        widget.ads.bannerDismissedForSession ||
        banner == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: ColoredBox(
        color: const Color(0xFF091522),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Reklam',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .45),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    tooltip: 'Reklamı kapat',
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    constraints: const BoxConstraints.tightFor(
                      width: 32,
                      height: 24,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
            SizedBox(
              width: banner.size.width.toDouble(),
              height: banner.size.height.toDouble(),
              child: AdWidget(ad: banner),
            ),
          ],
        ),
      ),
    );
  }
}
