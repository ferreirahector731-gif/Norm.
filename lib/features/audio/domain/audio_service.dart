import 'dart:io';
import 'dart:isolate';

import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_track.dart';
import 'jamendo_client.dart';

class AudioService {
  final AudioPlayer _player = AudioPlayer();
  final JamendoClient _jamendo = JamendoClient();
  AudioTrack? _currentTrack;
  AudioPlaybackState _state = AudioPlaybackState.idle;
  double _volume = 1.0;
  bool _isShuffling = false;
  LoopMode _loopMode = LoopMode.off;
  List<AudioTrack> _queue = [];

  AudioTrack? get currentTrack => _currentTrack;
  AudioPlaybackState get state => _state;
  double get volume => _volume;
  bool get isShuffling => _isShuffling;
  LoopMode get loopMode => _loopMode;
  List<AudioTrack> get queue => List.unmodifiable(_queue);
  Duration get position => _player.position;
  Duration get duration => _player.duration ?? Duration.zero;
  bool get isPlaying => _player.playing;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  JamendoClient get jamendo => _jamendo;

  AudioService() {
    _player.playerStateStream.listen((ps) {
      _state = ps.processingState == ProcessingState.completed
          ? AudioPlaybackState.stopped
          : ps.playing
              ? AudioPlaybackState.playing
              : AudioPlaybackState.paused;
    });
  }

  Future<void> playLocal(String filePath) async {
    _state = AudioPlaybackState.loading;
    final file = File(filePath);
    if (!await file.exists()) {
      _state = AudioPlaybackState.error;
      throw Exception('Archivo no encontrado: $filePath');
    }
    final bytes = await _loadInIsolate(filePath);
    _currentTrack = AudioTrack(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      title: file.uri.pathSegments.last,
      sourceType: AudioSourceType.local,
      sourcePath: filePath,
    );
    await _player.setAudioSource(AudioSource.uri(Uri.file(filePath)));
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> playStream(String url, {String? title, String? artist}) async {
    _state = AudioPlaybackState.loading;
    _currentTrack = AudioTrack(
      id: 'stream_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? url.split('/').last,
      artist: artist,
      sourceType: AudioSourceType.streaming,
      sourcePath: url,
    );
    await _player.setAudioSource(AudioSource.uri(Uri.parse(url)));
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> playTrack(AudioTrack track) async {
    _currentTrack = track;
    _state = AudioPlaybackState.loading;
    await _player.setAudioSource(AudioSource.uri(Uri.parse(track.sourcePath)));
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> playQueue(List<AudioTrack> tracks, {int startIndex = 0}) async {
    _queue = List.from(tracks);
    if (_queue.isEmpty) return;
    final clips = tracks
        .map((t) => AudioSource.uri(Uri.parse(t.sourcePath)))
        .toList();
    _currentTrack = tracks[startIndex];
    _state = AudioPlaybackState.loading;
    await _player.setAudioSource(ConcatenatingAudioSource(children: clips), initialIndex: startIndex);
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> pause() async {
    await _player.pause();
    _state = AudioPlaybackState.paused;
  }

  Future<void> resume() async {
    await _player.play();
    _state = AudioPlaybackState.playing;
  }

  Future<void> stop() async {
    await _player.stop();
    _state = AudioPlaybackState.stopped;
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> setVolume(double vol) async {
    _volume = vol.clamp(0.0, 1.0);
    await _player.setVolume(_volume);
  }

  void toggleShuffle() {
    _isShuffling = !_isShuffling;
    _player.setShuffleModeEnabled(_isShuffling);
  }

  void cycleLoopMode() {
    _loopMode = switch (_loopMode) {
      LoopMode.off => LoopMode.one,
      LoopMode.one => LoopMode.all,
      LoopMode.all => LoopMode.off,
    };
    _player.setLoopMode(_loopMode);
  }

  Future<void> skipNext() async {
    if (_queue.isEmpty) return;
    await _player.seekToNext();
  }

  Future<void> skipPrevious() async {
    if (_queue.isEmpty) return;
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
    } else {
      await _player.seekToPrevious();
    }
  }

  Future<Uint8List> _loadInIsolate(String filePath) async {
    return await Isolate.run(() {
      final file = File(filePath);
      return file.readAsBytesSync();
    });
  }

  void dispose() {
    _player.dispose();
    _jamendo.dispose();
  }
}
