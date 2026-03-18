import 'package:flutter/material.dart';

class HomeVideosPlaylist extends StatefulWidget {
  final String playlistId;
  final bool infiniteLoop;
  final bool isLoading;
  final List<dynamic> movies;
  final ValueChanged<String> onLoadMore;
  final String Function(String url) normalizeImageUrl;

  const HomeVideosPlaylist({
    super.key,
    required this.playlistId,
    required this.infiniteLoop,
    required this.isLoading,
    required this.movies,
    required this.onLoadMore,
    required this.normalizeImageUrl,
  });

  @override
  State<HomeVideosPlaylist> createState() => _HomeVideosPlaylistState();
}

class _HomeVideosPlaylistState extends State<HomeVideosPlaylist> {
  static const double _threshold = 200.0;
  bool _armed = true;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (!widget.infiniteLoop) return false;
          if (widget.playlistId.isEmpty) return false;
          if (widget.isLoading) return false;

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
              widget.onLoadMore(widget.playlistId);
            });
          }
          return false;
        },
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: widget.movies.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) => _MovieCard(
            item: widget.movies[index],
            normalizeImageUrl: widget.normalizeImageUrl,
          ),
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final dynamic item;
  final String Function(String url) normalizeImageUrl;

  const _MovieCard({required this.item, required this.normalizeImageUrl});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? movie = item is Map ? (item['movie'] as Map?) : null;
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
          AspectRatio(
            aspectRatio: 3 / 2,
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

