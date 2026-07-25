import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'audio_track.dart';

class JamendoClient {
  static const _baseUrl = 'https://api.jamendo.com/v3.0';
  static const _clientId = '3e18ed5b';

  final http.Client _http;

  JamendoClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  void dispose() => _http.close();

  Future<List<AudioTrack>> searchTracks({
    String? search,
    String? genre,
    int limit = 20,
    int offset = 0,
  }) async {
    final params = <String, String>{
      'client_id': _clientId,
      'format': 'json',
      'limit': limit.toString(),
      'offset': offset.toString(),
      'order': 'popularity_total',
    };
    if (search != null && search.isNotEmpty) {
      params['search'] = search;
    }
    if (genre != null && genre.isNotEmpty) {
      params['tags'] = genre;
    }

    final uri = Uri.parse('$_baseUrl/tracks').replace(queryParameters: params);
    final response = await _http.get(uri);

    if (response.statusCode != 200) {
      throw Exception('Jamendo API error: ${response.statusCode}');
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    return results.map((r) => _parseTrack(r as Map<String, dynamic>)).toList();
  }

  Future<List<String>> fetchGenres() async {
    final uri = Uri.parse('$_baseUrl/genres').replace(queryParameters: {
      'client_id': _clientId,
      'format': 'json',
      'limit': '50',
    });
    final response = await _http.get(uri);
    if (response.statusCode != 200) return [];
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final results = body['results'] as List<dynamic>? ?? [];
    return results
        .map((r) => r['name'] as String?)
        .where((n) => n != null)
        .cast<String>()
        .toList();
  }

  Future<Uint8List?> fetchAudioData(String audioUrl) async {
    final response = await _http.get(Uri.parse(audioUrl));
    if (response.statusCode == 200) return response.bodyBytes;
    return null;
  }

  AudioTrack _parseTrack(Map<String, dynamic> json) {
    final durationSec = double.tryParse(json['duration']?.toString() ?? '0') ?? 0;
    return AudioTrack(
      id: json['id']?.toString() ?? '',
      title: json['name'] as String? ?? 'Sin título',
      artist: json['artist_name'] as String?,
      albumArtUrl: json['image'] as String?,
      duration: Duration(milliseconds: (durationSec * 1000).round()),
      sourceType: AudioSourceType.jamendo,
      sourcePath: json['audio'] as String? ?? '',
    );
  }
}
