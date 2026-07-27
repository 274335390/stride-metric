import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:stride_metric/core/app_state.dart';
import 'package:stride_metric/core/shoe_catalog.dart';
import 'package:stride_metric/l10n/app_localizations.dart';
import 'package:stride_metric/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ShoeCatalog catalog;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    catalog = await ShoeCatalog.load();
  });

  testWidgets('main conversion flow renders and opens a result', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pump();

    expect(find.text('鞋码换算'), findsOneWidget);
    expect(find.text('换算'), findsOneWidget);
    expect(find.text('对照表'), findsOneWidget);
    expect(find.text('档案'), findsOneWidget);

    await tester.tap(find.text('开始换算'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('换算结果'), findsOneWidget);
    expect(find.text('对应尺码'), findsOneWidget);
  });

  testWidgets('dark mode applies to the complete app shell', (tester) async {
    SharedPreferences.setMockInitialValues({'darkMode': true});
    final state = AppState(catalog, await SharedPreferences.getInstance());
    await state.setLanguage(AppLanguage.simplifiedChinese);
    await state.setDarkMode(true);

    await tester.pumpWidget(StrideMetricApp(state: state));
    await tester.pump();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
  });
}
