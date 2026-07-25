import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import 'audio_provider.dart';
import '../domain/audio_track.dart';

class DraggableAudioOverlay extends StatefulWidget {
  const DraggableAudioOverlay({super.key});

  @override
  State<DraggableAudioOverlay> createState() => _DraggableAudioOverlayState();
}

class _DraggableAudioOverlayState extends State<DraggableAudioOverlay> {
  Offset _position = const Offset(16, 120);
  bool _minimized = false;

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioProvider>();
    final track = audio.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final size = MediaQuery.of(context).size;
    final clamped = Offset(
      _position.dx.clamp(0, size.width - (_minimized ? 60 : 320)),
      _position.dy.clamp(0, size.height - (_minimized ? 60 : 400)),
    );

    return Positioned(
      left: clamped.dx,
      top: clamped.dy,
      child: _minimized
          ? _MiniPlayer(track: track, audio: audio, onTap: () => setState(() => _minimized = false))
          : _FullPlayer(
              audio: audio,
              onMinimize: () => setState(() => _minimized = true),
              onDrag: (delta) => setState(() => _position += delta),
            ),
    );
  }
}

class _MiniPlayer extends StatelessWidget {
  final AudioTrack track;
  final AudioProvider audio;
  final VoidCallback onTap;

  const _MiniPlayer({required this.track, required this.audio, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(color: scheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: Center(
                child: audio.isPlaying
                    ? Icon(Icons.pause_rounded, color: scheme.primary, size: 22)
                    : Icon(Icons.play_arrow_rounded, color: scheme.primary, size: 22),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FullPlayer extends StatelessWidget {
  final AudioProvider audio;
  final VoidCallback onMinimize;
  final ValueChanged<Offset> onDrag;
  bool _expanded = false;
  bool get expanded => _expanded;

  _FullPlayer({required this.audio, required this.onMinimize, required this.onDrag});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track = audio.currentTrack!;
    final playerBody = expanded ? _buildExpanded(context, scheme, track) : _buildCompact(context, scheme, track);

    return GestureDetector(
      onPanUpdate: (details) => onDrag(details.delta),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        width: expanded ? 320 : 300,
        decoration: BoxDecoration(
          color: isDark
              ? scheme.surfaceContainer.withOpacity(0.95)
              : scheme.surfaceContainer.withOpacity(0.95),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outline.withOpacity(0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: isDark
              ? BackdropFilter(filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20), child: playerBody)
              : playerBody,
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context, ColorScheme scheme, AudioTrack track) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildArtwork(track, 36, scheme),
          const SizedBox(width: 8),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface),
                ),
                if (track.artist != null)
                  Text(
                    track.artist!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          _AnimatedBars(playing: audio.isPlaying, color: scheme.primary),
          IconButton(
            onPressed: audio.isPlaying ? audio.pause : audio.resume,
            icon: Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: scheme.primary, size: 20),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            onPressed: onMinimize,
            icon: Icon(Icons.minimize, color: scheme.onSurfaceVariant, size: 16),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildExpanded(BuildContext context, ColorScheme scheme, AudioTrack track) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildArtwork(track, 48, scheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: scheme.onSurface)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (track.artist != null) Text(track.artist!, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 6),
                        _buildSourceBadge(track.sourceType, scheme),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onMinimize,
                icon: Icon(Icons.keyboard_arrow_down, color: scheme.onSurfaceVariant, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                      value: dur.inMilliseconds > 0 ? pos.inMilliseconds / dur.inMilliseconds : 0,
                      onChanged: (v) => audio.seek(Duration(milliseconds: (v * dur.inMilliseconds).round())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(pos), style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
                        Text(_formatDuration(dur), style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: audio.toggleShuffle,
                child: Icon(Icons.shuffle, size: 16, color: audio.isShuffling ? scheme.primary : scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 8),
              GestureDetector(onTap: audio.skipPrevious, child: Icon(Icons.skip_previous_rounded, color: scheme.onSurface, size: 20)),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                child: IconButton(
                  onPressed: audio.isPlaying ? audio.pause : audio.resume,
                  icon: Icon(audio.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: scheme.onPrimary, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(onTap: audio.skipNext, child: Icon(Icons.skip_next_rounded, color: scheme.onSurface, size: 20)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: audio.cycleLoopMode,
                child: Icon(
                  audio.loopMode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                  size: 16,
                  color: audio.loopMode != LoopMode.off ? scheme.primary : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.volume_up, size: 12, color: scheme.onSurfaceVariant),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 3),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 6),
                    activeTrackColor: scheme.primary,
                    inactiveTrackColor: scheme.outline.withOpacity(0.3),
                    thumbColor: scheme.primary,
                  ),
                  child: Slider(value: audio.volume, onChanged: (v) => audio.setVolume(v)),
                ),
              ),
            ],
          ),
          if (audio.queue.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('${audio.queue.length} en cola', style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
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
        borderRadius: BorderRadius.circular(8),
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        image: track.albumArtUrl != null
            ? DecorationImage(image: NetworkImage(track.albumArtUrl!), fit: BoxFit.cover)
            : null,
      ),
      child: track.albumArtUrl == null
          ? Icon(Icons.music_note, size: size * 0.45, color: scheme.onSurfaceVariant)
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
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(3)),
      child: Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: color)),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _AnimatedBars extends StatefulWidget {
  final bool playing;
  final Color color;
  const _AnimatedBars({required this.playing, required this.color});

  @override
  State<_AnimatedBars> createState() => _AnimatedBarsState();
}

class _AnimatedBarsState extends State<_AnimatedBars>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    if (widget.playing) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedBars old) {
    super.didUpdateWidget(old);
    if (widget.playing != old.playing) {
      if (widget.playing) {
        _ctrl.repeat(reverse: true);
      } else {
        _ctrl.stop();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.playing) return const SizedBox(width: 18);
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return SizedBox(
          width: 16,
          height: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(3, (i) {
              final h = 3 + (_ctrl.value * 9 * (0.5 + i * 0.25));
              return Container(width: 2, height: h,
                decoration: BoxDecoration(color: widget.color.withOpacity(0.8), borderRadius: BorderRadius.circular(1)));
            }),
          ),
        );
      },
    );
  }
}

class AudioPlayerWidget extends StatelessWidget {
  const AudioPlayerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const DraggableAudioOverlay();
  }
}
