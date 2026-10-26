// lib/l10n/locale_controller.dart
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ÉNUMÉRATION DES LANGUES SUPPORTÉES ---

/// Langues disponibles dans GameFlix avec leur code ISO, drapeau et libellé natif.
enum AppLocale {
  fr('fr', '🇫🇷', 'Français'),
  en('en', '🇬🇧', 'English'),
  es('es', '🇪🇸', 'Español');

  final String code;
  final String flag;
  final String label;

  const AppLocale(this.code, this.flag, this.label);

  /// Résout une langue à partir de son code ISO ('fr', 'en', 'es').
  /// Retourne le français par défaut si le code est inconnu.
  static AppLocale fromCode(String? code) {
    if (code == null) return AppLocale.fr;
    for (final locale in AppLocale.values) {
      if (locale.code == code.toLowerCase()) {
        return locale;
      }
    }
    return AppLocale.fr;
  }
}

// --- CONTRÔLEUR DE LANGUE GLOBAL ---

/// Contrôleur gérant la langue active de l'application et sa persistance.
class LocaleController extends ChangeNotifier {
  static const String _prefsKey = 'selected_locale';

  /// Instance singleton accessible par les services sans BuildContext (ex: PackLoaderService).
  static final LocaleController instance = LocaleController();

  AppLocale _currentLocale = AppLocale.fr;
  bool _isLoaded = false;

  // --- GETTERS D'ÉTAT ---

  AppLocale get currentLocale => _currentLocale;
  String get languageCode => _currentLocale.code;
  String get flag => _currentLocale.flag;
  bool get isLoaded => _isLoaded;

  // --- CHARGEMENT & PERSISTANCE ---

  /// Charge la langue sauvegardée depuis SharedPreferences.
  Future<void> load() async {
    // 1. Lecture de la préférence stockée sur l'appareil
    final prefs = await SharedPreferences.getInstance();
    final String? savedCode = prefs.getString(_prefsKey);

    // 2. Mise à jour de la langue active (fallback sur FR)
    _currentLocale = AppLocale.fromCode(savedCode);
    _isLoaded = true;

    // 3. Notification des écouteurs UI
    notifyListeners();
  }

  /// Change la langue active et sauvegarde le choix dans SharedPreferences.
  Future<void> setLocale(AppLocale newLocale) async {
    if (_currentLocale == newLocale) return;

    // 1. Application immédiate en mémoire
    _currentLocale = newLocale;
    notifyListeners();

    // 2. Sauvegarde asynchrone dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, newLocale.code);
  }

  @visibleForTesting
  void resetForTest() {
    _currentLocale = AppLocale.fr;
    _isLoaded = false;
  }
}
