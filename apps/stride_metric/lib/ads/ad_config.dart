import 'package:flutter/foundation.dart';

abstract final class AdConfig {
  static const _androidBannerProduction = String.fromEnvironment(
    'ADMOB_ANDROID_BANNER_ID',
  );
  static const _androidAppOpenProduction = String.fromEnvironment(
    'ADMOB_ANDROID_APP_OPEN_ID',
  );

  static const _androidBannerTest = 'ca-app-pub-3940256099942544/9214589741';
  static const _androidAppOpenTest = 'ca-app-pub-3940256099942544/9257395921';
  static const _iosBannerTest = 'ca-app-pub-3940256099942544/2435281174';
  static const _iosAppOpenTest = 'ca-app-pub-3940256099942544/5575463023';

  static bool get usesProductionAds =>
      kReleaseMode &&
      _androidBannerProduction.isNotEmpty &&
      _androidAppOpenProduction.isNotEmpty;

  static String get bannerAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return usesProductionAds ? _androidBannerProduction : _androidBannerTest;
    }
    return _iosBannerTest;
  }

  static String get appOpenAdUnitId {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return usesProductionAds
          ? _androidAppOpenProduction
          : _androidAppOpenTest;
    }
    return _iosAppOpenTest;
  }
}
