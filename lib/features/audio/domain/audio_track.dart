enum AudioSourceType { local, streaming, jamendo }

enum AudioPlaybackState { idle, loading, playing, paused, stopped, error }

class AudioTrack {
  final String id;
  final String title;
  final String? artist;
  final String? albumArtUrl;
  final Duration duration;
  final AudioSourceType sourceType;
  final String sourcePath;

  const AudioTrack({
    required this.id,
    required this.title,
    this.artist,
    this.albumArtUrl,
    this.duration = Duration.zero,
    required this.sourceType,
    required this.sourcePath,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'artist': artist,
        'albumArtUrl': albumArtUrl,
        'duration': duration.inMilliseconds,
        'sourceType': sourceType.index,
        'sourcePath': sourcePath,
      };

  factory AudioTrack.fromJson(Map<String, dynamic> json) => AudioTrack(
        id: json['id'] as String,
        title: json['title'] as String,
        artist: json['artist'] as String?,
        albumArtUrl: json['albumArtUrl'] as String?,
        duration: Duration(milliseconds: json['duration'] as int? ?? 0),
        sourceType: AudioSourceType.values[json['sourceType'] as int? ?? 0],
        sourcePath: json['sourcePath'] as String,
      );
}
