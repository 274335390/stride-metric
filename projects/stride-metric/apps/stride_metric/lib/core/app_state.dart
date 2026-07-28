import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'models.dart';
import 'shoe_catalog.dart';

class AppState extends ChangeNotifier {
  AppState(this.catalog, this._preferences);

  final ShoeCatalog catalog;
  final SharedPreferences _preferences;

  int tabIndex = 0;
  Audience audience = Audience.women;
  LengthUnit unit = LengthUnit.cm;
  ConversionInput input = ConversionInput.footLength;
  SizeSystem knownSystem = SizeSystem.eu;
  double footMm = 260;
  num knownValue = 41;
  bool darkMode = false;
  AppLanguage language = AppLanguage.fromTag(null);
  String selectedBrand = 'Nike';
  ConversionResult? lastResult;
  final List<ConversionResult> recent = [];
  final List<ShoeProfile> profiles = [];

  static Future<AppState> load() async {
    final catalog = await ShoeCatalog.load();
    final preferences = await SharedPreferences.getInstance();
    final state = AppState(catalog, preferences);
    state.language = AppLanguage.fromTag(preferences.getString('language'));
    state.unit =
        LengthUnit.values[preferences.getInt('lengthUnit')?.clamp(0, 2) ??
            LengthUnit.cm.index];
    state.darkMode = preferences.getBool('darkMode') ?? false;
    state.selectedBrand = preferences.getString('selectedBrand') ?? 'Nike';
    state._loadProfiles();
    return state;
  }

  void _loadProfiles() {
    final raw = _preferences.getString('profiles');
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        profiles.addAll(
          list.map((item) {
            final value = item as Map<String, dynamic>;
            return ShoeProfile(
              name: value['name'] as String,
              audience: Audience.values[(value['audience'] as num).toInt()],
              leftFootMm: (value['leftFootMm'] as num).toDouble(),
              rightFootMm: (value['rightFootMm'] as num).toDouble(),
              width: _stableWidth(value['width'] as String?),
            );
          }),
        );
      } catch (_) {
        profiles.clear();
      }
    }
    if (profiles.isEmpty) {
      final copy = AppLocalizations(language);
      profiles.add(
        ShoeProfile(
          name: copy.t('myProfiles'),
          audience: Audience.women,
          leftFootMm: 258,
          rightFootMm: 260,
          width: 'wide',
        ),
      );
    }
  }

  static String _stableWidth(String? value) => switch (value) {
    '偏窄' || 'narrow' => 'narrow',
    '偏宽' || 'wide' => 'wide',
    _ => 'regular',
  };

  Future<void> saveProfile(ShoeProfile profile, {String? originalName}) async {
    final index = originalName == null
        ? -1
        : profiles.indexWhere((item) => item.name == originalName);
    if (index >= 0) {
      profiles[index] = profile;
    } else {
      final duplicate = profiles.indexWhere(
        (item) => item.name == profile.name,
      );
      if (duplicate >= 0) {
        profiles[duplicate] = profile;
      } else {
        profiles.add(profile);
      }
    }
    await _preferences.setString(
      'profiles',
      jsonEncode(
        profiles
            .map(
              (item) => {
                'name': item.name,
                'audience': item.audience.index,
                'leftFootMm': item.leftFootMm,
                'rightFootMm': item.rightFootMm,
                'width': item.width,
              },
            )
            .toList(growable: false),
      ),
    );
    notifyListeners();
  }

  void selectTab(int index) {
    tabIndex = index;
    notifyListeners();
  }

  void setAudience(Audience value) {
    audience = value;
    if (value == Audience.child) {
      footMm = footMm.clamp(120, 236);
    } else {
      footMm = footMm.clamp(205, 320);
    }
    notifyListeners();
  }

  void setInput(ConversionInput value) {
    input = value;
    notifyListeners();
  }

  void setFootMm(double value) {
    footMm = value;
    notifyListeners();
  }

  void setKnownSystem(SizeSystem value) {
    knownSystem = value;
    notifyListeners();
  }

  void setKnownValue(num value) {
    knownValue = value;
    notifyListeners();
  }

  Future<void> setUnit(LengthUnit value) async {
    unit = value;
    await _preferences.setInt('lengthUnit', value.index);
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage value) async {
    language = value;
    await _preferences.setString('language', value.tag);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    darkMode = value;
    await _preferences.setBool('darkMode', value);
    notifyListeners();
  }

  Future<void> setBrand(String value) async {
    selectedBrand = value;
    await _preferences.setString('selectedBrand', value);
    notifyListeners();
  }

  CatalogMatch resolveConversion() => input == ConversionInput.footLength
      ? catalog.matchFootLength(footMm, audience)
      : catalog.matchKnownSize(knownSystem, knownValue, audience);

  ConversionResult? convert() {
    final match = resolveConversion();
    final row = match.row;
    if (row == null) return null;
    final result = ConversionResult(
      row: row,
      audience: audience,
      input: input,
      inputSystem: input == ConversionInput.knownSize ? knownSystem : null,
      inputValue: input == ConversionInput.knownSize ? knownValue : null,
    );
    lastResult = result;
    recent
      ..removeWhere(
        (item) =>
            item.row.footMm == result.row.footMm &&
            item.audience == result.audience,
      )
      ..insert(0, result);
    if (recent.length > 4) recent.removeLast();
    notifyListeners();
    return result;
  }
}
