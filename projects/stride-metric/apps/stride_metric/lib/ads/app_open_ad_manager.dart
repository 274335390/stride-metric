import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ad_config.dart';

class AppOpenAdManager {
  AppOpenAdManager._();

  static final instance = AppOpenAdManager._();
  static const _launchCountKey = 'adLaunchCount';
  static const _lastShownKey = 'appOpenAdLastShownAt';
  static const _minimumInterval = Duration(hours: 4);

  AppOpenAd? _ad;
  DateTime? _loadedAt;
  bool _isShowing = false;
  bool _eligibleThisLaunch = false;
  Completer<void>? _launchGate;
  Timer? _launchTimeout;

  Future<void> initializeForLaunch() async {
    if (kIsWeb) return;
    await MobileAds.instance.initialize();
    final preferences = await SharedPreferences.getInstance();
    final launches = preferences.getInt(_launchCountKey) ?? 0;
    await preferences.setInt(_launchCountKey, launches + 1);
    _eligibleThisLaunch = launches >= 1 && _intervalHasElapsed(preferences);

    if (!_eligibleThisLaunch) {
      return;
    }

    _launchGate = Completer<void>();
    _launchTimeout = Timer(const Duration(milliseconds: 2500), () {
      _eligibleThisLaunch = false;
      _completeLaunchGate();
    });
    load();
    await _launchGate!.future;
  }

  bool _intervalHasElapsed(SharedPreferences preferences) {
    if (kDebugMode) return true;
    final milliseconds = preferences.getInt(_lastShownKey);
    if (milliseconds == null) return true;
    final lastShown = DateTime.fromMillisecondsSinceEpoch(milliseconds);
    return DateTime.now().difference(lastShown) >= _minimumInterval;
  }

  bool get _isFresh =>
      _loadedAt != null &&
      DateTime.now().difference(_loadedAt!) < const Duration(hours: 4);

  void load() {
    if (_ad != null && _isFresh) return;
    _ad?.dispose();
    _ad = null;
    AppOpenAd.load(
      adUnitId: AdConfig.appOpenAdUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _ad = ad;
          _loadedAt = DateTime.now();
          showIfAvailable();
        },
        onAdFailedToLoad: (error) {
          debugPrint('App-open ad failed to load: $error');
          _ad = null;
          _loadedAt = null;
          _eligibleThisLaunch = false;
          _completeLaunchGate();
        },
      ),
    );
  }

  Future<void> showIfAvailable() async {
    if (!_eligibleThisLaunch || _isShowing) return;
    final ad = _ad;
    if (ad == null || !_isFresh) {
      load();
      return;
    }

    _isShowing = true;
    _eligibleThisLaunch = false;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (_) async {
        final preferences = await SharedPreferences.getInstance();
        await preferences.setInt(
          _lastShownKey,
          DateTime.now().millisecondsSinceEpoch,
        );
      },
      onAdDismissedFullScreenContent: (dismissedAd) {
        _restoreAppSystemBars();
        dismissedAd.dispose();
        _ad = null;
        _loadedAt = null;
        _isShowing = false;
        _completeLaunchGate();
        load();
      },
      onAdFailedToShowFullScreenContent: (failedAd, error) {
        debugPrint('App-open ad failed to show: $error');
        _restoreAppSystemBars();
        failedAd.dispose();
        _ad = null;
        _loadedAt = null;
        _isShowing = false;
        _completeLaunchGate();
        load();
      },
    );
    ad.show();
  }

  void _restoreAppSystemBars() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemStatusBarContrastEnforced: false,
        systemNavigationBarContrastEnforced: false,
      ),
    );
  }

  void _completeLaunchGate() {
    _launchTimeout?.cancel();
    _launchTimeout = null;
    final gate = _launchGate;
    if (gate != null && !gate.isCompleted) gate.complete();
  }

  Future<void> dispose() async {
    _completeLaunchGate();
    _ad?.dispose();
    _ad = null;
  }
}
