# StrideMetric

StrideMetric is an offline international shoe-size conversion app for Android and iOS. It keeps generic standards, brand-published charts and personal size profiles separate so users can understand what a result represents.

StrideMetric 是一款面向 Android 和 iOS 的离线国际鞋码换算应用。它将通用标准、品牌官方尺码表和个人尺码档案分开处理，避免把不同口径混成一张“万能表”。

## Highlights

- Standard shoe-size conversion for EU, UK, US, JP and KR systems
- Adult women, adult men and children flows
- Brand-specific charts with measured foot length and shoe-label values kept distinct
- Local personal profiles and recent conversions
- Millimetre, centimetre and inch display preferences
- Offline-first Flutter implementation
- 13 interface languages:
  English, Türkçe, Deutsch, Español, Français, Italiano, Português (Brasil), 日本語, 한국어, 简体中文, Русский, Nederlands and हिन्दी

## Status

Active development. The current codebase includes the Flutter app, structured data, validation scripts and product/architecture documentation. Store releases have not been published yet.

## Project layout

```text
stride-metric/
├─ apps/stride_metric/          # Flutter application
├─ packages/size_domain/        # Pure Dart conversion domain
├─ data/                        # Structured source and dataset registry
├─ docs/                        # Product, UX, architecture and audit notes
└─ scripts/                     # Data validation
```

## Run the Flutter app

Requirements:

- Flutter SDK compatible with the version recorded in `pubspec.lock`
- Android Studio for Android, or Xcode for iOS

```bash
cd projects/stride-metric/apps/stride_metric
flutter pub get
flutter run
```

## Verify

```bash
cd projects/stride-metric/apps/stride_metric
flutter analyze
flutter test

cd ../../
node scripts/validate-data.mjs
```

## Data principles

1. Store canonical foot length internally in millimetres.
2. Preserve a brand’s published labels instead of filling missing values with a universal formula.
3. Keep measured foot length separate from the CM/JP value printed on a shoe label.
4. Retain source URL, market, audience, version and verification status with each dataset.
5. Never ship raw licensed standards or page scans in the app or repository.

See [DATA_NOTICE.md](DATA_NOTICE.md) before redistributing or commercialising any dataset or brand asset.

## Product identity

- Product name: **StrideMetric**
- Chinese display name: **鞋码换算**
- Android application ID: `com.stridemetric.shoe`
- iOS bundle identifier: `com.stridemetric.shoe`

The name was checked against public web, GitHub, App Store and Google Play search results on 2026-07-27, but this is not a trademark clearance.

## License

Source code is available under the [MIT License](LICENSE). Dataset and trademark rights are described separately in [DATA_NOTICE.md](DATA_NOTICE.md).
