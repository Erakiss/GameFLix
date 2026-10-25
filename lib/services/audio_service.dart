// lib/services/audio_service.dart
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --- ÉNUMÉRATION DES EFFETS SONORES ---

/// Catalogue des effets sonores disponibles dans GameFlix.
enum SoundEffect {
  /// Clic moderne pour boutons, switches et interactions UI
  click,

  /// Tic-tac d'horloge pour les timers et comptes à rebours
  timerTick,

  /// Son d'échec / buzzer / temps écoulé / pénalité
  buzzer,

  /// Jingle fanfare de victoire et confettis
  victory,

  /// Roulement de dés (Jeu de plateau)
  dice,

  /// Nappe de suspense / révélation secrète (Imposteur / Codenames)
  suspense,

  /// Glissement de carte physique (Action ou Vérité / Tu préfères)
  cardSlide,
}

// --- SERVICE AUDIO GLOBAL ---

/// Gestionnaire audio centralisé gérant l'ambiance musicale (BGM) et les bruitages (SFX).
class AudioService extends ChangeNotifier {
  /// Instance singleton pour l'ensemble de l'application
  static final AudioService instance = AudioService._();

  AudioService._();

  AudioPlayer? _bgmPlayerInstance;
  AudioPlayer? _sfxPlayerInstance;

  AudioPlayer get _bgmPlayer => _bgmPlayerInstance ??= AudioPlayer();
  AudioPlayer get _sfxPlayer => _sfxPlayerInstance ??= AudioPlayer();

  bool _isMuted = false;
  double _volume = 0.6; // Volume par défaut à 60% (3 barres sur 5)
  bool _isBgmPlaying = false;
  bool _isInitialized = false;

  // --- GETTERS D'ÉTAT ---

  bool get isMuted => _isMuted;
  double get volume => _volume;
  bool get isBgmPlaying => _isBgmPlaying;

  /// Niveau discret de volume entre 1 et 5 (utilisé pour les barres de l'égaliseur)
  int get volumeLevel {
    if (_isMuted || _volume <= 0.0) return 0;
    return max(1, min(5, (_volume * 5).round()));
  }

  // --- INITIALISATION & CONFIGURATION SYSTÈME ---

  /// Initialise la persistance et configure le respect de la musique externe (Spotify / Apple Music).
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Configuration de l'AudioContext pour ne pas couper Spotify
      if (!kIsWeb && !Platform.environment.containsKey('FLUTTER_TEST')) {
        await AudioPlayer.global.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: false,
              contentType: AndroidContentType.music,
              usageType: AndroidUsageType.game,
              audioFocus: AndroidAudioFocus.none, // Ne vole pas le focus des applications musicales
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.mixWithOthers, // Mixe le son par-dessus la musique externe
              },
            ),
          ),
        );
      }

      // 2. Chargement des préférences sauvegardées
      final prefs = await SharedPreferences.getInstance();
      _isMuted = prefs.getBool('audio_is_muted') ?? false;
      _volume = prefs.getDouble('audio_volume') ?? 0.6;

      // 3. Application du volume aux lecteurs
      await _applyVolume();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'initialisation AudioService: $e');
    }
  }

  // --- GESTION DU BGM (MUSIQUE D'AMBIANCE) ---

  /// Lance la musique d'ambiance en boucle pour le Hub.
  Future<void> playBgm() async {
    try {
      // 1. Configuration en mode répétition infinie
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      // 2. Application du volume doux d'ambiance
      await _applyVolume();

      // 3. Démarrage de la piste
      await _bgmPlayer.play(AssetSource('audio/bgm_hub.wav'));
      _isBgmPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la lecture du BGM: $e');
    }
  }

  /// Met en pause la musique d'ambiance.
  Future<void> pauseBgm() async {
    try {
      await _bgmPlayer.pause();
      _isBgmPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la mise en pause du BGM: $e');
    }
  }

  /// Reprend la musique d'ambiance si elle était en pause.
  Future<void> resumeBgm() async {
    try {
      await _bgmPlayer.resume();
      _isBgmPlaying = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de la reprise du BGM: $e');
    }
  }

  /// Arrête définitivement la musique d'ambiance.
  Future<void> stopBgm() async {
    try {
      await _bgmPlayer.stop();
      _isBgmPlaying = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du BGM: $e');
    }
  }

  // --- GESTION DES SFX (EFFETS SONORES) ---

  /// Joue un effet sonore ponctuel selon le type demandé.
  Future<void> playSfx(SoundEffect effect) async {
    if (_isMuted || _volume <= 0.0) return;

    try {
      // 1. Résolution du chemin d'asset associé
      final assetPath = getSfxAssetPath(effect);

      // 2. Configuration du volume SFX
      await _sfxPlayer.setVolume(_volume);

      // 3. Lecture immédiate
      await _sfxPlayer.play(AssetSource(assetPath), mode: PlayerMode.lowLatency);
    } catch (e) {
      debugPrint('Erreur lors de la lecture SFX ($effect): $e');
    }
  }

  /// Retourne le chemin relatif du fichier audio pour un effet donné.
  String getSfxAssetPath(SoundEffect effect) {
    switch (effect) {
      case SoundEffect.click:
        return 'audio/sfx_click.ogg';
      case SoundEffect.timerTick:
        return 'audio/sfx_timer_tick.ogg';
      case SoundEffect.buzzer:
        return 'audio/sfx_buzzer.ogg';
      case SoundEffect.victory:
        return 'audio/sfx_victory.ogg';
      case SoundEffect.dice:
        return 'audio/sfx_dice.ogg';
      case SoundEffect.suspense:
        return 'audio/sfx_suspense.ogg';
      case SoundEffect.cardSlide:
        return 'audio/sfx_card_slide.ogg';
    }
  }

  // --- CONTRÔLES DE VOLUME & MUTE ---

  /// Bascule l'état Mute (on/off) et sauvegarde le choix.
  Future<void> toggleMute() async {
    // 1. Inversion du flag
    _isMuted = !_isMuted;

    // 2. Application immédiate aux flux audio
    await _applyVolume();

    // 3. Sauvegarde dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_is_muted', _isMuted);

    notifyListeners();
  }

  /// Règle le volume général entre 0.0 et 1.0.
  Future<void> setVolume(double newVolume) async {
    // 1. Bornage de la valeur
    _volume = max(0.0, min(1.0, newVolume));

    // 2. Si un volume positif est choisi, on réactive le son
    if (_isMuted && _volume > 0.0) {
      _isMuted = false;
    }

    // 3. Application aux lecteurs
    await _applyVolume();

    // 4. Sauvegarde dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_volume', _volume);
    await prefs.setBool('audio_is_muted', _isMuted);

    notifyListeners();
  }

  /// Règle le volume selon un palier entier de 1 à 5 (barres de l'égaliseur).
  Future<void> setVolumeLevel(int level) async {
    final clampedLevel = max(1, min(5, level));
    await setVolume(clampedLevel * 0.2);
  }

  /// Met à jour les volumes internes des deux lecteurs audioplayers.
  Future<void> _applyVolume() async {
    try {
      final double effectiveBgmVolume = _isMuted ? 0.0 : (_volume * 0.35); // BGM plus discret
      final double effectiveSfxVolume = _isMuted ? 0.0 : _volume;

      if (_bgmPlayerInstance != null) {
        await _bgmPlayerInstance!.setVolume(effectiveBgmVolume);
      }
      if (_sfxPlayerInstance != null) {
        await _sfxPlayerInstance!.setVolume(effectiveSfxVolume);
      }
    } catch (_) {
      // Ignoré lors des tests unitaires sans moteur natif
    }
  }

  @visibleForTesting
  void resetForTest() {
    _bgmPlayerInstance?.dispose();
    _sfxPlayerInstance?.dispose();
    _bgmPlayerInstance = null;
    _sfxPlayerInstance = null;
    _isInitialized = false;
    _isMuted = false;
    _volume = 0.6;
    _isBgmPlaying = false;
  }

  @override
  void dispose() {
    _bgmPlayerInstance?.dispose();
    _sfxPlayerInstance?.dispose();
    _bgmPlayerInstance = null;
    _sfxPlayerInstance = null;
    super.dispose();
  }
}
