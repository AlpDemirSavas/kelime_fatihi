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
  BannerAd? _banner;
  bool _loading = false;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didUpdateWidget(covariant DismissibleBannerAd oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (!oldWidget.isAdFree && widget.isAdFree) {
      _disposeBanner();
      return;
    }

    if (oldWidget.ads != widget.ads) {
      _disposeBanner();
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    if (!mounted ||
        _loading ||
        _dismissed ||
        widget.isAdFree ||
        widget.ads.bannerDismissedForSession) {
      return;
    }

    _loading = true;
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
      setState(() => _banner = banner);
    }
  }

  void _dismiss() {
    widget.ads.dismissBannerForSession();
    _dismissed = true;
    _disposeBanner();
    if (mounted) setState(() {});
  }

  void _disposeBanner() {
    _banner?.dispose();
    _banner = null;
  }

  @override
  void dispose() {
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
