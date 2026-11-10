import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride_metric/core/app_state.dart';
import 'package:stride_metric/core/shoe_catalog.dart';
import 'package:stride_metric/l10n/app_localizations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all 13 listed languages are present and every key is translated', () {
    expect(AppLanguage.values, hasLength(13));
    expect(AppLanguage.supportedLocales, hasLength(13));
    expect(AppLocalizations.keys, isNotEmpty);
    expect(AppLocalizations.hasCompleteCoverage(), isTrue);
  });

  test('locale matching supports regional tags and safe English fallback', () {
    expect(AppLanguage.fromTag('pt-BR'), AppLanguage.portugueseBrazil);
    expect(AppLanguage.fromTag('zh_CN'), AppLanguage.simplifiedChinese);
    expect(AppLanguage.fromTag('ja'), AppLanguage.japanese);
    expect(
      AppLanguage.fromTag('xx', systemLocale: const Locale('xx')),
      AppLanguage.english,
    );
  });

  test('language selection persists between app sessions', () async {
    SharedPreferences.setMockInitialValues({});
    final catalog = await ShoeCatalog.load();
    final state = AppState(catalog, await SharedPreferences.getInstance());

    await state.setLanguage(AppLanguage.korean);

    final reloaded = await AppState.load();
    expect(reloaded.language, AppLanguage.korean);
    expect(AppLocalizations(reloaded.language).t('appTitle'), '신발 사이즈 변환');
  });
}
