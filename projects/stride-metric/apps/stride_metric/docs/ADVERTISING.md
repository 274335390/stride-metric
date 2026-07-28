# Advertising configuration

StrideMetric uses Google Mobile Ads on Android and iOS.

## Open-source defaults

- Debug and profile builds always use Google's official test ad units.
- Production ad unit IDs are read from Dart build definitions only in release
  mode.
- The Android AdMob App ID is read from the ignored
  `android/local.properties` file.
- `.env` and `android/local.properties` are ignored by Git.
- `.env.example` and `android/local.properties.example` contain placeholders
  for forks.

Forks therefore show test ads until the maintainer supplies their own AdMob
application and ad unit IDs.

## Local Android setup

Add the application ID to the existing ignored `android/local.properties`:

```properties
admob.androidAppId=ca-app-pub-REPLACE_ME~REPLACE_ME
```

Copy `.env.example` to `.env` and add the two Android ad unit IDs:

```dotenv
ADMOB_ANDROID_BANNER_ID=ca-app-pub-REPLACE_ME/REPLACE_ME
ADMOB_ANDROID_APP_OPEN_ID=ca-app-pub-REPLACE_ME/REPLACE_ME
```

Build the production Android App Bundle:

```powershell
.\tool\build_android_release.ps1
```

Running `flutter run` continues to use test ads, even when local production
configuration exists.

## Placement and frequency

- The home conversion page uses an anchored adaptive banner. A failed request
  collapses without leaving an empty placeholder.
- The app-open ad starts from the second app launch.
- App-open impressions are limited to at most one every four hours.
- A missing or late app-open ad never blocks application startup.

## Before publishing

1. Configure the privacy and consent message in AdMob.
2. Publish and verify `app-ads.txt` on the developer website.
3. Complete Google Play's Ads and Data safety declarations.
4. Test only with test ads or a configured test device.
5. Add production IDs to CI secrets rather than repository variables.
