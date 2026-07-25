import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'audio_provider.dart';
import '../domain/audio_track.dart';

class AudioPlayerWidget extends StatefulWidget {
  const AudioPlayerWidget({super.key});

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainer.withOpacity(0.92)
              : scheme.surfaceContainer.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
              blurRadius: 16,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: isDark
                ? null
                : null,
            child: _expanded ? _buildExpanded(audio, scheme) : _buildCompact(audio, scheme, track),
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(AudioProvider audio, ColorScheme scheme, AudioTrack track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _buildArtwork(track, 40, scheme),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (track.artist != null) ...[
                      Text(
                        track.artist!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    _buildSourceBadge(track.sourceType, scheme),
                  ],
                ),
              ],
            ),
          ),
          _buildAnimatedIndicator(audio, scheme),
          const SizedBox(width: 8),
          IconButton(
            onPressed: audio.isPlaying ? audio.pause : audio.resume,
            icon: Icon(
              audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: scheme.primary,
            ),
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(AudioProvider audio, ColorScheme scheme) {
    final track = audio.currentTrack!;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildArtwork(track, 56, scheme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (track.artist != null) ...[
                          Text(
                            track.artist!,
                            style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(width: 8),
                        ],
                        _buildSourceBadge(track.sourceType, scheme),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _expanded = false),
                icon: Icon(Icons.keyboard_arrow_down, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<Duration>(
            stream: audio.positionStream,
            builder: (context, snapshot) {
              final pos = snapshot.data ?? Duration.zero;
              final dur = audio.duration;
              return Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                      overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                      activeTrackColor: scheme.primary,
                      inactiveTrackColor: scheme.outline.withOpacity(0.3),
                      thumbColor: scheme.primary,
                    ),
                    child: Slider(
                      value: dur.inMilliseconds > 0
                          ? pos.inMilliseconds / dur.inMilliseconds
                          : 0.0,
                      onChanged: (v) => audio.seek(Duration(milliseconds: (v * dur.inMilliseconds).round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(pos), style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                        Text(_formatDuration(dur), style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: audio.toggleShuffle,
                icon: Icon(Icons.shuffle, size: 18),
                color: audio.isShuffling ? scheme.primary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: audio.skipPrevious,
                icon: const Icon(Icons.skip_previous_rounded),
                color: scheme.onSurface,
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  color: scheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: audio.isPlaying ? audio.pause : audio.resume,
                  icon: Icon(
                    audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: scheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                onPressed: audio.skipNext,
                icon: const Icon(Icons.skip_next_rounded),
                color: scheme.onSurface,
              ),
              const SizedBox(width: 12),
              IconButton(
                onPressed: audio.cycleLoopMode,
                icon: Icon(
                  audio.loopMode == LoopMode.one
                      ? Icons.repeat_one
                      : Icons.repeat,
                  size: 18,
                ),
                color: audio.loopMode != LoopMode.off ? scheme.primary : scheme.onSurfaceVariant,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.volume_up, size: 14, color: scheme.onSurfaceVariant),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.outline.withOpacity(0.3),
                    thumbColor: scheme.primary,
                  ),
                  child: Slider(
                    value: audio.volume,
                    onChanged: (v) => audio.setVolume(v),
                  ),
                ),
              ),
            ],
          ),
          if (audio.queue.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '${audio.queue.length} temas en cola',
                style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArtwork(AudioTrack track, double size, ColorScheme scheme) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        image: track.albumArtUrl != null
            ? DecorationImage(
                image: NetworkImage(track.albumArtUrl!),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: track.albumArtUrl == null
          ? Icon(Icons.music_note, size: size * 0.5, color: scheme.onSurfaceVariant)
          : null,
    );
  }

  Widget _buildSourceBadge(AudioSourceType type, ColorScheme scheme) {
    final (label, color) = switch (type) {
      AudioSourceType.local => ('Local', const Color(0xFF34D399)),
      AudioSourceType.streaming => ('Stream', const Color(0xFF38BDF8)),
      AudioSourceType.jamendo => ('Jamendo', const Color(0xFFA78BFA)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildAnimatedIndicator(AudioProvider audio, ColorScheme scheme) {
    if (!audio.isPlaying) return const SizedBox(width: 24);
    return AnimatedBuilder(
      animation: _pulseCtrl,
      builder: (context, _) {
        return SizedBox(
          width: 20,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              final height = 4 + (_pulseCtrl.value * 12 * (0.6 + i * 0.2));
              return Container(
                width: 2.5,
                height: height,
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(1),
                ),
              );
            }),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
