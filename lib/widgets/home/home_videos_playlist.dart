import 'package:flutter/material.dart';

class HomeVideosPlaylist extends StatefulWidget {
  final String playlistId;
  final bool hasMore;
  final bool isLoading;
  final bool loopToStart;
  final List<dynamic> movies;
  final ValueChanged<String> onLoadMore;
  final String Function(String url) normalizeImageUrl;

  const HomeVideosPlaylist({
    super.key,
    required this.playlistId,
    required this.hasMore,
    required this.isLoading,
    required this.loopToStart,
    required this.movies,
    required this.onLoadMore,
    required this.normalizeImageUrl,
  });

  @override
  State<HomeVideosPlaylist> createState() => _HomeVideosPlaylistState();
}

class _HomeVideosPlaylistState extends State<HomeVideosPlaylist> {
  final ScrollController _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleScrollLogic(ScrollMetrics metrics) {
    if (widget.playlistId.isEmpty || widget.isLoading) return;
    if (metrics.maxScrollExtent <= 0) return;

    if (widget.loopToStart && metrics.pixels >= metrics.maxScrollExtent) {
      _controller.jumpTo(0);
      // _controller.animateTo(
      //   0,
      //   duration: const Duration(milliseconds: 500),
      //   curve: Curves.easeOut,
      // );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 220,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification ||
              notification is ScrollEndNotification) {
            _handleScrollLogic(notification.metrics);
          }
          return false;
        },
        child: ListView.separated(
          controller: _controller,
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
    final Map<dynamic, dynamic>? movieData =
        item is Map && item.containsKey('movie')
        ? item['movie']
        : (item is Map ? item : null);

    final String title = movieData != null
        ? (movieData['title'] ?? '').toString()
        : '';

    final String posterUrl = normalizeImageUrl(
      movieData != null
          ? (movieData['poster'] ?? movieData['banner'] ?? '').toString()
          : '',
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
              child: Container(
                color: Colors.black12,
                child: posterUrl.isNotEmpty
                    ? Image.network(
                        posterUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Center(child: Icon(Icons.broken_image)),
                      )
                    : const Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              title,
              maxLines: 1,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
