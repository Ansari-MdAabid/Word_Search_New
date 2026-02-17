// lib/services/sound_manager.dart - IMPROVED VERSION with proper app lifecycle management

import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:get_storage/get_storage.dart';

class SoundManager {
  static final SoundManager _instance = SoundManager._internal();
  factory SoundManager() => _instance;
  SoundManager._internal();

  AudioPlayer? _soundPlayer;
  AudioPlayer? _musicPlayer;
  GetStorage? _storage;

  bool _soundEnabled = true;
  bool _musicEnabled = true;
  double _soundVolume = 1.0;
  double _musicVolume = 1.0;
  bool _isInitialized = false;
  bool _isMusicPlaying = false;
  bool _shouldBePlaying = false; // Track if music should be playing
  bool _isPausedByLifecycle = false; // Track if paused by app lifecycle

  // Initialize sound system
  Future<void> init() async {
    // If already initialized, just return (idempotent)
    if (_isInitialized) {
      print('SoundManager: Already initialized, skipping');
      return;
    }
    
    try {
      print('SoundManager: Initializing...');
      
      // Initialize GetStorage if not already done
      try {
        await GetStorage.init();
        _storage = GetStorage();
      } catch (e) {
        print('SoundManager: GetStorage init warning: $e');
        // Continue even if storage fails, use defaults
      }
      
      // Load saved settings with safety checks
      _soundEnabled = _storage?.read('sound_enabled') ?? true;
      _musicEnabled = _storage?.read('music_enabled') ?? true;
      _soundVolume = _storage?.read('sound_volume') ?? 1.0;
      _musicVolume = _storage?.read('music_volume') ?? 1.0;

      // Create players with error handling
      try {
        _soundPlayer = AudioPlayer();
        _musicPlayer = AudioPlayer();
        
        // Set volumes
        await _soundPlayer!.setVolume(_soundVolume);
        await _musicPlayer!.setVolume(_musicVolume);
      } catch (e) {
        print('SoundManager: AudioPlayer creation failed: $e');
        // If audio players fail, mark as initialized but possibly non-functional
        // This prevents app crash but audio won't work
        _isInitialized = true; 
        return;
      }

      // Set up music player event listeners
      _musicPlayer!.onPlayerStateChanged.listen((PlayerState state) {
        _isMusicPlaying = (state == PlayerState.playing);
        // print('Music player state changed: $state, isMusicPlaying: $_isMusicPlaying');
      });

      // Handle music completion (shouldn't happen with loop, but just in case)
      _musicPlayer!.onPlayerComplete.listen((event) {
        // print('Music completed - restarting if should be playing');
        if (_shouldBePlaying && _musicEnabled && !_isPausedByLifecycle) {
          _startMusicLoop();
        }
      });

      _isInitialized = true;
      print('SoundManager: Initialized successfully');
      
    } catch (e) {
      print('SoundManager: Critical init failure: $e');
      // Don't rethrow, just log and continue without sound
    }
  }

  // Internal method to start music loop
  Future<void> _startMusicLoop() async {
    if (!_isInitialized || !_musicEnabled || _musicPlayer == null) return;
    if (_isMusicPlaying) return; // Don't start if already playing

    try {
      await _musicPlayer!.setReleaseMode(ReleaseMode.loop);
      await _musicPlayer!.play(AssetSource('sounds/background_music.mp3'));
      _shouldBePlaying = true;
      print('Music loop started successfully');
    } catch (e) {
      print('Failed to start music loop: $e');
    }
  }

  // Internal method to stop music
  Future<void> _stopMusic() async {
    if (_musicPlayer == null) return;
    
    try {
      await _musicPlayer!.stop();
      _shouldBePlaying = false;
      print('Music stopped');
    } catch (e) {
      print('Failed to stop music: $e');
    }
  }

  // Play sound effects
  Future<void> playSound(String soundName) async {
    if (!_isInitialized || !_soundEnabled || _soundPlayer == null) return;

    try {
      await _soundPlayer!.play(AssetSource('sounds/$soundName.mp3'));
    } catch (e) {
      print('Sound failed: $soundName - $e');
    }
  }

  // Start background music - more reliable
  Future<void> startBackgroundMusic() async {
    print('startBackgroundMusic called - musicEnabled: $_musicEnabled, isMusicPlaying: $_isMusicPlaying');
    
    if (!_musicEnabled) {
      print('Music disabled, not starting');
      return;
    }
    
    if (_isMusicPlaying) {
      print('Music already playing');
      return;
    }
    
    _isPausedByLifecycle = false;
    await _startMusicLoop();
  }

  // Stop background music
  Future<void> stopBackgroundMusic() async {
    print('stopBackgroundMusic called');
    await _stopMusic();
    _isPausedByLifecycle = false;
  }

  // NEW: Pause background music (for app lifecycle)
  void pauseBackgroundMusic() {
    print('pauseBackgroundMusic called - isMusicPlaying: $_isMusicPlaying');
    
    if (_musicPlayer == null) return;
    
    try {
      if (_isMusicPlaying) {
        print('Pausing background music due to app lifecycle');
        _musicPlayer!.pause();
        _isPausedByLifecycle = true;
      }
    } catch (e) {
      print('Error pausing background music: $e');
    }
  }

  // NEW: Resume background music (for app lifecycle)
  void resumeBackgroundMusic() {
    print('resumeBackgroundMusic called - isPausedByLifecycle: $_isPausedByLifecycle, shouldBePlaying: $_shouldBePlaying, musicEnabled: $_musicEnabled');
    
    if (_musicPlayer == null || !_musicEnabled) return;
    
    try {
      if (_isPausedByLifecycle && _shouldBePlaying) {
        print('Resuming background music from pause');
        _musicPlayer!.resume();
        _isPausedByLifecycle = false;
      } else if (!_isMusicPlaying && _shouldBePlaying) {
        // If music was stopped instead of paused, restart it
        print('Restarting background music');
        _isPausedByLifecycle = false;
        _startMusicLoop();
      }
    } catch (e) {
      print('Error resuming background music: $e');
    }
  }

  // DEPRECATED: Keep for backward compatibility but redirect to new methods
  void onAppPause() {
    print('onAppPause called - redirecting to pauseBackgroundMusic');
    pauseBackgroundMusic();
  }

  void onAppResume() {
    print('onAppResume called - redirecting to resumeBackgroundMusic');
    // Small delay to ensure app is fully resumed
    Future.delayed(const Duration(milliseconds: 500), () {
      resumeBackgroundMusic();
    });
  }

  // Game start event - more reliable
  void onGameStart() {
    print('onGameStart called - starting background music');
    
    if (_musicEnabled) {
      // Set flag that music should be playing
      _shouldBePlaying = true;
      _isPausedByLifecycle = false;
      
      // Start music with slight delay to avoid conflicts
      Future.delayed(const Duration(milliseconds: 200), () {
        startBackgroundMusic();
      });
    }
  }

  // Level complete with star sequence
  void onLevelComplete(int stars) {
    playLevelComplete();
    for (int i = 0; i < stars; i++) {
      Future.delayed(Duration(milliseconds: 400 * i), () {
        playStarEarned();
      });
    }
  }

  // Individual sound methods
  Future<void> playWordFound() async {
    HapticFeedback.lightImpact();
    await playSound('word_found');
  }

  Future<void> playInvalidSelection() async {
    HapticFeedback.lightImpact();
    await playSound('invalid_selection');
  }

  Future<void> playTileSelect() async {
    HapticFeedback.selectionClick();
    await playSound('tile_select');
  }

  Future<void> playLevelComplete() async {
    HapticFeedback.mediumImpact();
    await playSound('level_complete');
  }

  Future<void> playStarEarned() async {
    HapticFeedback.lightImpact();
    await playSound('star_earned');
  }

  Future<void> playButtonClick() async {
    HapticFeedback.selectionClick();
    await playSound('button_click');
  }

  Future<void> playPageTransition() async {
    await playSound('page_transition');
  }

  Future<void> playHintUsed() async {
    HapticFeedback.mediumImpact();
    await playSound('hint_used');
  }

  Future<void> playCelebration() async {
    HapticFeedback.heavyImpact();
    await playSound('celebration');
  }

  // Settings with better music control
  bool get soundEnabled => _soundEnabled;
  bool get musicEnabled => _musicEnabled;
  double get soundVolume => _soundVolume;
  double get musicVolume => _musicVolume;
  
  // NEW: Getter to check if music is currently playing
  bool get isBackgroundMusicPlaying => _isMusicPlaying;

  set soundEnabled(bool value) {
    _soundEnabled = value;
    _storage?.write('sound_enabled', value);
    print('Sound enabled set to: $value');
  }

  set musicEnabled(bool value) {
    print('Setting music enabled to: $value');
    _musicEnabled = value;
    _storage?.write('music_enabled', value);
    
    if (value) {
      _shouldBePlaying = true;
      _isPausedByLifecycle = false;
      startBackgroundMusic();
    } else {
      _shouldBePlaying = false;
      _isPausedByLifecycle = false;
      stopBackgroundMusic();
    }
  }

  set soundVolume(double value) {
    _soundVolume = value.clamp(0.0, 1.0);
    _soundPlayer?.setVolume(_soundVolume);
    _storage?.write('sound_volume', _soundVolume);
  }

  set musicVolume(double value) {
    _musicVolume = value.clamp(0.0, 1.0);
    _musicPlayer?.setVolume(_musicVolume);
    _storage?.write('music_volume', _musicVolume);
  }

  // Debug info method
  void debugPrintStatus() {
    print('''
SoundManager Status:
- Initialized: $_isInitialized
- Music Enabled: $_musicEnabled
- Sound Enabled: $_soundEnabled
- Music Playing: $_isMusicPlaying
- Should Be Playing: $_shouldBePlaying
- Paused by Lifecycle: $_isPausedByLifecycle
- Music Volume: $_musicVolume
- Sound Volume: $_soundVolume
''');
  }

  // Cleanup
  void dispose() {
    print('SoundManager disposing');
    _shouldBePlaying = false;
    _isPausedByLifecycle = false;
    _soundPlayer?.dispose();
    _musicPlayer?.dispose();
  }
}