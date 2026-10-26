// lib/services/audio_service.dart
import 'dart:io' show Platform;
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
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

/// Gestionnaire audio centralisé gérant :
/// 1. Le volume maître global (`volume`) et 2 toggles indépendants (`isBgmMuted`, `isSfxMuted`).
/// 2. La mise en pause/reprise automatique selon le cycle de vie de l'application (`WidgetsBindingObserver`).
class AudioService extends ChangeNotifier with WidgetsBindingObserver {
  /// Instance singleton pour l'ensemble de l'application
  static final AudioService instance = AudioService._();

  AudioService._();

  AudioPlayer? _bgmPlayerInstance;
  AudioPlayer? _sfxPlayerInstance;

  AudioPlayer get _bgmPlayer => _bgmPlayerInstance ??= AudioPlayer();
  AudioPlayer get _sfxPlayer => _sfxPlayerInstance ??= AudioPlayer();

  bool _isBgmMuted = false;
  bool _isSfxMuted = false;
  double _volume = 0.6; // Volume maître par défaut à 60% (3 barres sur 5)
  bool _isBgmPlaying = false;
  bool _wasBgmPlayingBeforePause = false;
  bool _isInitialized = false;

  // --- GETTERS D'ÉTAT ---

  /// Indique si à la fois la musique et les bruitages sont coupés (ou volume à 0).
  bool get isMuted => (_isBgmMuted && _isSfxMuted) || _volume <= 0.0;

  /// Indique si la musique d'ambiance (BGM) est coupée.
  bool get isBgmMuted => _isBgmMuted;

  /// Indique si les effets sonores (SFX) sont coupés.
  bool get isSfxMuted => _isSfxMuted;

  /// Indique si la musique d'ambiance (BGM) est activée.
  bool get isBgmEnabled => !_isBgmMuted;

  /// Indique si les effets sonores (SFX) sont activés.
  bool get isSfxEnabled => !_isSfxMuted;

  /// Volume maître global entre 0.0 et 1.0.
  double get volume => _volume;

  /// Indique si le lecteur BGM est actuellement en lecture active.
  bool get isBgmPlaying => _isBgmPlaying;

  /// Indique si le BGM jouait avant la mise en arrière-plan de l'application.
  bool get wasBgmPlayingBeforePause => _wasBgmPlayingBeforePause;

  /// Niveau discret de volume entre 0 et 5 (utilisé pour les barres de l'égaliseur).
  int get volumeLevel {
    if (isMuted || _volume <= 0.0) return 0;
    return max(1, min(5, (_volume * 5).round()));
  }

  // --- INITIALISATION & CONFIGURATION SYSTÈME ---

  /// Initialise la persistance, l'observateur de cycle de vie et le mixage avec Spotify / Apple Music.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      // 1. Enregistrement de l'observateur du cycle de vie de l'application
      WidgetsBinding.instance.addObserver(this);

      // 2. Configuration de l'AudioContext pour ne pas couper Spotify
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

      // 3. Chargement des préférences sauvegardées (avec rétrocompatibilité 'audio_is_muted')
      final prefs = await SharedPreferences.getInstance();
      final bool legacyMuted = prefs.getBool('audio_is_muted') ?? false;
      _isBgmMuted = prefs.getBool('audio_bgm_muted') ?? legacyMuted;
      _isSfxMuted = prefs.getBool('audio_sfx_muted') ?? legacyMuted;
      _volume = prefs.getDouble('audio_volume') ?? 0.6;

      // 4. Application du volume aux lecteurs
      await _applyVolume();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur d\'initialisation AudioService: $e');
    }
  }

  // --- CYCLE DE VIE DE L'APPLICATION (WIDGETSBINDINGOBSERVER) ---

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 1. Retour au premier plan : on ne relance le BGM que s'il jouait avant la pause et n'est pas mute
      if (_wasBgmPlayingBeforePause) {
        _wasBgmPlayingBeforePause = false;
        if (!_isBgmMuted) {
          resumeBgm();
        }
      }
    } else {
      // 2. Passage en arrière-plan / écran éteint (inactive, paused, hidden, detached) :
      // on stoppe immédiatement les SFX et on met en pause la musique
      _sfxPlayerInstance?.stop();
      if (_isBgmPlaying) {
        _wasBgmPlayingBeforePause = true;
        pauseBgm();
      }
    }
  }

  // --- GESTION DU BGM (MUSIQUE D'AMBIANCE) ---

  /// Lance la musique d'ambiance en boucle pour le Hub.
  Future<void> playBgm() async {
    _isBgmPlaying = true;
    notifyListeners();
    try {
      // 1. Configuration en mode répétition infinie
      await _bgmPlayer.setReleaseMode(ReleaseMode.loop);

      // 2. Application du volume doux d'ambiance
      await _applyVolume();

      // 3. Démarrage de la piste
      await _bgmPlayer.play(AssetSource('audio/bgm_hub.wav'));
    } catch (e) {
      debugPrint('Erreur lors de la lecture du BGM: $e');
    }
  }

  /// Met en pause la musique d'ambiance.
  Future<void> pauseBgm() async {
    _isBgmPlaying = false;
    notifyListeners();
    try {
      await _bgmPlayer.pause();
    } catch (e) {
      debugPrint('Erreur lors de la mise en pause du BGM: $e');
    }
  }

  /// Reprend la musique d'ambiance si elle était en pause.
  Future<void> resumeBgm() async {
    _isBgmPlaying = true;
    notifyListeners();
    try {
      await _applyVolume();
      await _bgmPlayer.resume();
    } catch (e) {
      debugPrint('Erreur lors de la reprise du BGM: $e');
    }
  }

  /// Arrête définitivement la musique d'ambiance.
  Future<void> stopBgm() async {
    _isBgmPlaying = false;
    _wasBgmPlayingBeforePause = false;
    notifyListeners();
    try {
      await _bgmPlayer.stop();
    } catch (e) {
      debugPrint('Erreur lors de l\'arrêt du BGM: $e');
    }
  }

  // --- GESTION DES SFX (EFFETS SONORES) ---

  /// Joue un effet sonore ponctuel selon le type demandé.
  Future<void> playSfx(SoundEffect effect) async {
    if (_isSfxMuted || _volume <= 0.0) return;

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

  // --- CONTRÔLES DE VOLUME MAÎTRE & TOGGLES BGM / SFX ---

  /// Active ou coupe uniquement la musique d'ambiance (BGM) et sauvegarde le choix.
  Future<void> setBgmMuted(bool muted) async {
    // 1. Mise à jour du flag BGM
    _isBgmMuted = muted;

    // 2. Application immédiate au lecteur BGM
    await _applyVolume();

    // 3. Persistance dans SharedPreferences
    await _saveMutePrefs();
    notifyListeners();
  }

  /// Inverse l'état Mute de la musique d'ambiance (BGM).
  Future<void> toggleBgmMute() => setBgmMuted(!_isBgmMuted);

  /// Active ou coupe uniquement les effets sonores (SFX) et sauvegarde le choix.
  Future<void> setSfxMuted(bool muted) async {
    // 1. Mise à jour du flag SFX
    _isSfxMuted = muted;
    if (_isSfxMuted) {
      _sfxPlayerInstance?.stop();
    }

    // 2. Application immédiate au lecteur SFX
    await _applyVolume();

    // 3. Persistance dans SharedPreferences
    await _saveMutePrefs();
    notifyListeners();
  }

  /// Inverse l'état Mute des effets sonores (SFX).
  Future<void> toggleSfxMute() => setSfxMuted(!_isSfxMuted);

  /// Bascule l'état Mute global (BGM + SFX ensemble) et sauvegarde le choix.
  Future<void> toggleMute() async {
    // 1. Inversion globale (si tout est déjà coupé, on réactive tout ; sinon on coupe tout)
    final bool targetMute = !isMuted;
    _isBgmMuted = targetMute;
    _isSfxMuted = targetMute;

    // 2. Application immédiate aux flux audio
    await _applyVolume();

    // 3. Sauvegarde dans SharedPreferences
    await _saveMutePrefs();
    notifyListeners();
  }

  /// Règle le volume maître général entre 0.0 et 1.0.
  Future<void> setVolume(double newVolume) async {
    // 1. Bornage de la valeur
    _volume = max(0.0, min(1.0, newVolume));

    // 2. Si un volume positif est choisi alors que tout était coupé, on réactive le son
    if (_isBgmMuted && _isSfxMuted && _volume > 0.0) {
      _isBgmMuted = false;
      _isSfxMuted = false;
    }

    // 3. Application aux lecteurs
    await _applyVolume();

    // 4. Sauvegarde dans SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('audio_volume', _volume);
    await _saveMutePrefs();

    notifyListeners();
  }

  /// Règle le volume selon un palier entier de 1 à 5 (barres de l'égaliseur).
  Future<void> setVolumeLevel(int level) async {
    final clampedLevel = max(1, min(5, level));
    await setVolume(clampedLevel * 0.2);
  }

  Future<void> _saveMutePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('audio_bgm_muted', _isBgmMuted);
    await prefs.setBool('audio_sfx_muted', _isSfxMuted);
    await prefs.setBool('audio_is_muted', _isBgmMuted && _isSfxMuted);
  }

  /// Met à jour les volumes internes des deux lecteurs audioplayers.
  Future<void> _applyVolume() async {
    try {
      final double effectiveBgmVolume = _isBgmMuted ? 0.0 : (_volume * 0.35); // BGM plus discret
      final double effectiveSfxVolume = _isSfxMuted ? 0.0 : _volume;

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
    if (_isInitialized) {
      WidgetsBinding.instance.removeObserver(this);
    }
    _bgmPlayerInstance?.dispose();
    _sfxPlayerInstance?.dispose();
    _bgmPlayerInstance = null;
    _sfxPlayerInstance = null;
    _isInitialized = false;
    _isBgmMuted = false;
    _isSfxMuted = false;
    _volume = 0.6;
    _isBgmPlaying = false;
    _wasBgmPlayingBeforePause = false;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgmPlayerInstance?.dispose();
    _sfxPlayerInstance?.dispose();
    _bgmPlayerInstance = null;
    _sfxPlayerInstance = null;
    super.dispose();
  }
}
