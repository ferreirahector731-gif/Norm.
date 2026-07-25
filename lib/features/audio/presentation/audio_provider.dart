import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../domain/audio_service.dart';
import '../domain/audio_track.dart';
import '../domain/jamendo_client.dart';

class AudioProvider extends ChangeNotifier {
  final AudioService _service = AudioService();

  AudioService get service => _service;
  AudioTrack? get currentTrack => _service.currentTrack;
  AudioPlaybackState get state => _service.state;
  bool get isPlaying => _service.isPlaying;
  Duration get position => _service.position;
  Duration get duration => _service.duration;
  double get volume => _service.volume;
  bool get isShuffling => _service.isShuffling;
  LoopMode get loopMode => _service.loopMode;
  List<AudioTrack> get queue => _service.queue;
  Stream<Duration> get positionStream => _service.positionStream;
  Stream<PlayerState> get playerStateStream => _service.playerStateStream;
  JamendoClient get jamendo => _service.jamendo;

  Future<void> playLocal(String filePath) async {
    await _service.playLocal(filePath);
    notifyListeners();
  }

  Future<void> playStream(String url, {String? title, String? artist}) async {
    await _service.playStream(url, title: title, artist: artist);
    notifyListeners();
  }

  Future<void> playTrack(AudioTrack track) async {
    await _service.playTrack(track);
    notifyListeners();
  }

  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    await _service.playQueue(tracks, startIndex: startIndex);
    notifyListeners();
  }

  Future<void> pause() async {
    await _service.pause();
    notifyListeners();
  }

  Future<void> resume() async {
    await _service.resume();
    notifyListeners();
  }

  Future<void> stop() async {
    await _service.stop();
    notifyListeners();
  }

  Future<void> seek(Duration position) async {
    await _service.seek(position);
    notifyListeners();
  }

  Future<void> setVolume(double vol) async {
    await _service.setVolume(vol);
    notifyListeners();
  }

  void toggleShuffle() {
    _service.toggleShuffle();
    notifyListeners();
  }

  void cycleLoopMode() {
    _service.cycleLoopMode();
    notifyListeners();
  }

  Future<void> skipNext() async {
    await _service.skipNext();
    notifyListeners();
  }

  Future<void> skipPrevious() async {
    await _service.skipPrevious();
    notifyListeners();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}
