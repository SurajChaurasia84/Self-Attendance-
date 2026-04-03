import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

const bool _kIsFlutterTestEnv = bool.fromEnvironment('FLUTTER_TEST');

class BannerAdBar extends StatefulWidget {
  const BannerAdBar({
    super.key,
    required this.refreshToken,
  });

  final int refreshToken;

  @override
  State<BannerAdBar> createState() => _BannerAdBarState();
}

class _BannerAdBarState extends State<BannerAdBar> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;
  int? _lastWidth;

  bool get _shouldLoadRealAds => !_kIsFlutterTestEnv && !kIsWeb;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_shouldLoadRealAds) {
      return;
    }

    final int width = MediaQuery.of(context).size.width.truncate();
    if (_lastWidth == width) {
      return;
    }
    _lastWidth = width;
    _loadBannerAd(width);
  }

  @override
  void didUpdateWidget(covariant BannerAdBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_shouldLoadRealAds) {
      return;
    }
    if (oldWidget.refreshToken == widget.refreshToken) {
      return;
    }

    final int width = MediaQuery.of(context).size.width.truncate();
    _lastWidth = width;
    _loadBannerAd(width);
  }

  Future<void> _loadBannerAd(int width) async {
    final AdSize? adaptiveSize =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || adaptiveSize == null) {
      return;
    }

    await _bannerAd?.dispose();
    _bannerAd = null;
    _isLoaded = false;

    final BannerAd banner = BannerAd(
      size: adaptiveSize,
      adUnitId: Platform.isAndroid
          ? 'ca-app-pub-3940256099942544/6300978111'
          : 'ca-app-pub-3940256099942544/2934735716',
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (Ad ad) {
          if (!mounted) {
            ad.dispose();
            return;
          }
          setState(() {
            _bannerAd = ad as BannerAd;
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (Ad ad, LoadAdError error) {
          ad.dispose();
        },
      ),
    );

    banner.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: SizedBox(
        width: double.infinity,
        height: _bannerAd!.size.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}
