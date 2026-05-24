import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AgeMode { little, big }

extension AgeModeX on AgeMode {
  String get label => this == AgeMode.little ? 'Little (5-7)' : 'Big (8-10)';
  String get ageRange => this == AgeMode.little ? '5-7' : '8-10';
}

/// App-wide settings — singleton ChangeNotifier persisted to SharedPreferences.
/// Read with `AppSettings.instance.ageMode` etc.
/// Listen via `AnimatedBuilder(animation: AppSettings.instance, ...)`.
class AppSettings extends ChangeNotifier {
  AppSettings._();
  static final AppSettings instance = AppSettings._();

  static const _kAgeMode = 'kapoof.ageMode';
  static const _kBuilderMode = 'kapoof.builderMode';

  AgeMode _ageMode = AgeMode.little;
  bool _builderMode = false;
  bool _loaded = false;

  AgeMode get ageMode => _ageMode;
  bool get builderMode => _builderMode || _ageMode == AgeMode.big;
  bool get builderModeRaw => _builderMode;
  bool get loaded => _loaded;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final ageRaw = prefs.getString(_kAgeMode);
    _ageMode = ageRaw == 'big' ? AgeMode.big : AgeMode.little;
    _builderMode = prefs.getBool(_kBuilderMode) ?? false;
    _loaded = true;
    notifyListeners();
  }

  Future<void> setAgeMode(AgeMode mode) async {
    if (_ageMode == mode) return;
    _ageMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kAgeMode, mode == AgeMode.big ? 'big' : 'little');
    notifyListeners();
  }

  Future<void> setBuilderMode(bool enabled) async {
    if (_builderMode == enabled) return;
    _builderMode = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBuilderMode, enabled);
    notifyListeners();
  }
}
