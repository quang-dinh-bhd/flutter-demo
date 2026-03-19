import 'package:flutter/material.dart';

class HomeVideosPlaylist extends StatefulWidget {
  final String playlistId;
  final bool infiniteLoop;
  final bool isLoading;
  final List<dynamic> movies;
  final Future<void> Function(String) onLoadMore;
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
  late ScrollController _controller;

  static const double _itemFullWidth = 290.0;
  bool _isJumping = false;
  int _multipler = 3;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_handleScroll);

    _initListAndScroll();
  }

  void _initListAndScroll() {
    if (widget.movies.isEmpty) return;

    _multipler = widget.movies.length < 6 ? 10 : 3;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients && widget.infiniteLoop) {
        final middleIndex = (widget.movies.length * _multipler) ~/ 2;
        _controller.jumpTo(middleIndex * _itemFullWidth);
      }
    });
  }

  @override
  void didUpdateWidget(covariant HomeVideosPlaylist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.movies.length != widget.movies.length) {
      if (oldWidget.movies.isEmpty) _initListAndScroll();
    }
  }

  void _handleScroll() {
    if (!widget.infiniteLoop ||
        !_controller.hasClients ||
        widget.movies.isEmpty ||
        _isJumping)
      return;

    final offset = _controller.offset;
    final singleSetWidth = widget.movies.length * _itemFullWidth;
    final totalContentWidth = singleSetWidth * _multipler;

    if (offset >= totalContentWidth - (_itemFullWidth * 2)) {
      _isJumping = true;
      _controller.jumpTo(offset - singleSetWidth);
      _isJumping = false;
    } else if (offset <= _itemFullWidth) {
      _isJumping = true;
      _controller.jumpTo(offset + singleSetWidth);
      _isJumping = false;
    }

    if (offset > _controller.position.maxScrollExtent - 600 &&
        !widget.isLoading) {
      widget.onLoadMore(widget.playlistId);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) return const SizedBox(height: 220);

    final List<dynamic> displayList = [];
    if (widget.infiniteLoop) {
      for (var i = 0; i < _multipler; i++) {
        displayList.addAll(widget.movies);
      }
    } else {
      displayList.addAll(widget.movies);
    }

    return SizedBox(
      height: 220,
      child: ListView.separated(
        key: PageStorageKey('inf_v3_${widget.playlistId}'),
        controller: _controller,
        scrollDirection: Axis.horizontal,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        itemCount: displayList.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return _MovieCard(
            item: displayList[index],
            normalizeImageUrl: widget.normalizeImageUrl,
          );
        },
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
    final Map<dynamic, dynamic>? movie = item is Map
        ? (item['movie'] as Map?)
        : null;
    final String title = movie != null
        ? (movie['title'] ?? '').toString()
        : (item is Map ? (item['title'] ?? '').toString() : '');
    final String posterUrl = normalizeImageUrl(
      movie != null
          ? (movie['poster'] ?? movie['banner'] ?? '').toString()
          : (item is Map
                ? (item['poster'] ?? item['banner'] ?? '').toString()
                : ''),
    );

    return AspectRatio(
      aspectRatio: 2 / 3,

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              posterUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
