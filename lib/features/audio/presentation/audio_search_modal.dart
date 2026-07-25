import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/audio_track.dart';
import '../domain/jamendo_client.dart';
import 'audio_provider.dart';

const _genreOptions = [
  'lofi',
  'piano',
  'ambient',
  'scifi',
  'rock',
  'jazz',
  'classical',
  'electronic',
];

class AudioSearchModal extends StatefulWidget {
  const AudioSearchModal({super.key});

  @override
  State<AudioSearchModal> createState() => _AudioSearchModalState();
}

class _AudioSearchModalState extends State<AudioSearchModal> {
  final _searchCtrl = TextEditingController();
  String? _selectedGenre;
  List<AudioTrack> _results = [];
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(AudioProvider audio) async {
    final query = _searchCtrl.text.trim();
    if (query.isEmpty && _selectedGenre == null) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tracks = await audio.jamendo.searchTracks(
        search: query.isNotEmpty ? query : null,
        genre: _selectedGenre,
        limit: 20,
      );
      if (!mounted) return;
      setState(() {
        _results = tracks;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de búsqueda: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final audio = context.read<AudioProvider>();
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F0D1A)
            : const Color(0xFFF8FAFC),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHandle(scheme),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: (_) => _search(audio),
              style: TextStyle(color: scheme.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar canciones, artistas...',
                hintStyle: TextStyle(color: scheme.onSurfaceVariant.withOpacity(0.5)),
                prefixIcon: Icon(Icons.search, color: scheme.onSurfaceVariant),
                suffixIcon: IconButton(
                  icon: Icon(Icons.send_rounded, color: scheme.primary, size: 18),
                  onPressed: () => _search(audio),
                ),
                filled: true,
                fillColor: isDark
                    ? const Color(0xFF1A1830).withOpacity(0.6)
                    : const Color(0xFFE2E8F0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final genre in _genreOptions) ...[
                  _buildGenreChip(genre, scheme, audio),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            )
          else if (_results.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  _searchCtrl.text.isEmpty && _selectedGenre == null
                      ? 'Busca música o selecciona un género'
                      : 'Sin resultados',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _results.length,
                separatorBuilder: (_, __) => Divider(
                  height: 1,
                  color: scheme.outline.withOpacity(0.15),
                ),
                itemBuilder: (context, index) {
                  final track = _results[index];
                  return _buildTrackTile(track, audio, scheme);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHandle(ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4),
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: scheme.onSurfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildGenreChip(String genre, ColorScheme scheme, AudioProvider audio) {
    final selected = _selectedGenre == genre;
    return FilterChip(
      label: Text(
        genre[0].toUpperCase() + genre.substring(1),
        style: TextStyle(
          fontSize: 11,
          color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
        ),
      ),
      selected: selected,
      onSelected: (v) {
        setState(() => _selectedGenre = v ? genre : null);
        _search(audio);
      },
      selectedColor: scheme.primary,
      checkmarkColor: scheme.onPrimary,
      showCheckmark: false,
      backgroundColor: Colors.transparent,
      side: BorderSide(
        color: selected ? scheme.primary : scheme.outline.withOpacity(0.3),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  Widget _buildTrackTile(AudioTrack track, AudioProvider audio, ColorScheme scheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
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
                ? Icon(Icons.music_note, size: 20, color: scheme.onSurfaceVariant)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (track.artist != null)
                      Text(
                        track.artist!,
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                      ),
                    const Spacer(),
                    Text(
                      _formatDuration(track.duration),
                      style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              await audio.playTrack(track);
              if (context.mounted) Navigator.of(context).pop();
            },
            icon: Icon(Icons.play_circle_fill_rounded, color: scheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: scheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
