import 'package:flutter/material.dart';

class HomePlaylists extends StatelessWidget {
  final bool isLoading;
  final String currentModuleId;
  final List<dynamic> playlists;
  final Map<String, List<dynamic>> playlistMovies;
  final Set<String> loadingPlaylistMovies;
  final Map<String, bool> loadMore;
  final ValueChanged<String> onLoadMore;
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
          key: id.isNotEmpty ? ValueKey('playlist-$id') : null,
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
  final ValueChanged<String> onLoadMore;
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
  static const double _threshold = 200.0;
  bool _armed = true;

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
          )
        else if (movies == null || movies.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(child: Text("Không có video")),
          )
        else
          SizedBox(
            height: 170,
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                if (!infiniteLoop) return false;
                if (playlistId.isEmpty) return false;
                if (isLoadingMovies) return false;

                // When user scrolls near the end, auto load next page.
                final metrics = notification.metrics;
                if (metrics.maxScrollExtent <= 0) return false;
                final isNearEnd =
                    metrics.pixels >= (metrics.maxScrollExtent - _threshold);

                if (!isNearEnd) {
                  _armed = true;
                  return false;
                }

                if (!_armed) return false;

                if (notification is ScrollEndNotification) {
                  _armed = false;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    widget.onLoadMore(playlistId);
                  });
                }
                return false;
              },
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: movies.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) => _MovieCard(
                  item: movies[index],
                  normalizeImageUrl: widget.normalizeImageUrl,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _MovieCard extends StatelessWidget {
  final dynamic item;
  final String Function(String url) normalizeImageUrl;

  const _MovieCard({required this.item, required this.normalizeImageUrl});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? movie = item is Map
        ? (item['movie'] as Map?)
        : null;
    final String title = movie != null
        ? (movie['title'] ?? '').toString()
        : (item is Map ? (item['title'] ?? '').toString() : '');

    final String posterUrl = normalizeImageUrl(
      movie != null
          ? ((movie['poster'] ?? movie['banner'] ?? '').toString())
          : (item is Map
                ? ((item['poster'] ?? item['banner'] ?? '').toString())
                : ''),
    );

    return SizedBox(
      width: 280,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: posterUrl.isNotEmpty
                  ? Image.network(
                      posterUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) =>
                          const ColoredBox(
                            color: Colors.black12,
                            child: Center(child: Icon(Icons.broken_image)),
                          ),
                    )
                  : const ColoredBox(
                      color: Colors.black12,
                      child: Center(child: Icon(Icons.image_not_supported)),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
