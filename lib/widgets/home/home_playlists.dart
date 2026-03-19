import 'package:flutter/material.dart';

import 'home_videos_playlist.dart';

class HomePlaylists extends StatelessWidget {
  final bool isLoading;
  final String currentModuleId;
  final List<dynamic> playlists;
  final Map<String, List<dynamic>> playlistMovies;
  final Set<String> loadingPlaylistMovies;
  final Map<String, bool> loadMore;
  final Future<void> Function(String) onLoadMore;
  final String Function(String url) normalizeImageUrl;

  const HomePlaylists({
    super.key,
    required this.isLoading,
    required this.currentModuleId,
    required this.playlists,
    required this.playlistMovies,
    required this.loadingPlaylistMovies,
    required this.loadMore,
    required this.onLoadMore,
    required this.normalizeImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (currentModuleId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Nội dung chính")),
      );
    }

    if (playlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Không có playlist")),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: playlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        final playlist = playlists[index];
        final id = playlist is Map ? (playlist['id']?.toString() ?? '') : '';
        return _PlaylistSection(
          key: id.isNotEmpty
              ? ValueKey('playlist-$id-${playlistMovies[id]?.length ?? 0}')
              : null,
          playlist: playlist,
          movies: _getMovies(playlist),
          isLoadingMovies: _isLoadingMovies(playlist),
          hasMore: _hasMore(playlist),
          onLoadMore: onLoadMore,
          normalizeImageUrl: normalizeImageUrl,
        );
      },
    );
  }

  List<dynamic>? _getMovies(dynamic playlist) {
    final id = playlist is Map ? (playlist['id']?.toString() ?? '') : '';
    return id.isEmpty ? null : playlistMovies[id];
  }

  bool _isLoadingMovies(dynamic playlist) {
    final id = playlist is Map ? (playlist['id']?.toString() ?? '') : '';
    return id.isNotEmpty && loadingPlaylistMovies.contains(id);
  }

  bool _hasMore(dynamic playlist) {
    final id = playlist is Map ? (playlist['id']?.toString() ?? '') : '';
    return id.isNotEmpty && (loadMore[id] ?? true);
  }
}

class _PlaylistSection extends StatefulWidget {
  final dynamic playlist;
  final List<dynamic>? movies;
  final bool isLoadingMovies;
  final bool hasMore;
  final Future<void> Function(String) onLoadMore;
  final String Function(String url) normalizeImageUrl;

  const _PlaylistSection({
    super.key,
    required this.playlist,
    required this.movies,
    required this.isLoadingMovies,
    required this.hasMore,
    required this.onLoadMore,
    required this.normalizeImageUrl,
  });

  @override
  State<_PlaylistSection> createState() => _PlaylistSectionState();
}

class _PlaylistSectionState extends State<_PlaylistSection> {
  @override
  Widget build(BuildContext context) {
    final playlist = widget.playlist;
    final movies = widget.movies;
    final isLoadingMovies = widget.isLoadingMovies;

    final String name = playlist is Map
        ? (playlist['name'] ?? playlist['title'] ?? '').toString()
        : playlist.toString();
    final String playlistId = playlist is Map
        ? (playlist['id']?.toString() ?? '')
        : '';
    final bool infiniteLoop = (playlist is Map)
        ? ((playlist['is_infinite_loop']?.toString() ?? '0') == '1')
        : false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        if (isLoadingMovies && movies == null)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
        if (movies != null && movies.isNotEmpty)
          HomeVideosPlaylist(
            playlistId: playlistId,
            infiniteLoop: infiniteLoop,
            isLoading: isLoadingMovies,
            movies: movies,
            onLoadMore: widget.onLoadMore,
            normalizeImageUrl: widget.normalizeImageUrl,
          ),
      ],
    );
  }
}
