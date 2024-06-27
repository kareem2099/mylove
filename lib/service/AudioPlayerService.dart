import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AudioPlayerService with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  int _currentSongIndex = 0;
  double _currentVolume = 0.5; // Initial volume

  List<String> playlist = [
    'music/first.mp3',
    'music/sec.mp3', // Add your second song
    'music/third.mp3', // Add your third song
    'music/forth.mp3', // Add your forth song
    // Add more songs as needed
  ];

  bool get isPlaying => _isPlaying;
  String get currentSong => playlist[_currentSongIndex];
  double get currentVolume => _currentVolume;

  AudioPlayerService() {
    _setupAudioPlayer();
    _listenForAppLifecycleChanges();
  }


  Future<void> playBackgroundMusic() async {
    if (!_isPlaying) {
      await _audioPlayer.play(AssetSource(currentSong));
      _isPlaying = true;
      notifyListeners();
    }
  }

  Future<void> pauseBackgroundMusic() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
      _isPlaying = false;
      notifyListeners();
    }
  }

  Future<void> stopBackgroundMusic() async {
    if (_isPlaying) {
      await _audioPlayer.stop();
      _isPlaying = false;
      _currentSongIndex = 0; // Reset to the first song
      notifyListeners();
    }
  }

  void _playNextSong() {
    _currentSongIndex = (_currentSongIndex + 1) % playlist.length;
    playBackgroundMusic(); // Play the next song immediately
  }

  void _setupAudioPlayer() {
    _audioPlayer.onPlayerComplete.listen((event) {
      _playNextSong();
    });
  }



  void _listenForAppLifecycleChanges() {
    SystemChannels.lifecycle.setMessageHandler((message) async {
      if (message == AppLifecycleState.paused.toString()) {
        // App went into background, pause music
        await pauseBackgroundMusic();
      } else if (message == AppLifecycleState.resumed.toString()) {
        // App resumed, play music if it was playing before
        if (_isPlaying) {
          await playBackgroundMusic();
        }
      }
      return;
    });
  }

  void setVolume(double volume) {
    _currentVolume = volume;
    _audioPlayer.setVolume(_currentVolume);
    notifyListeners();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}