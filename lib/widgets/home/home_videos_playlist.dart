import 'package:flutter/material.dart';

class HomeVideosPlaylist extends StatefulWidget {
  final String playlistId;
  final bool infiniteLoop;
  final bool isLoading;
  final bool hasMore;
  final List<dynamic> movies;
  final Future<void> Function(String) onLoadMore;

  const HomeVideosPlaylist({
    super.key,
    required this.playlistId,
    required this.infiniteLoop,
    required this.isLoading,
    required this.hasMore,
    required this.movies,
    required this.onLoadMore,
  });

  @override
  State<HomeVideosPlaylist> createState() => _HomeVideosPlaylistState();
}

class _HomeVideosPlaylistState extends State<HomeVideosPlaylist> {
  late ScrollController _controller;

  static const double _itemWidth = 120.0;
  static const double _separatorWidth = 10.0;
  static const double _itemFullWidth = _itemWidth + _separatorWidth;

  static const int _multiplier = 20;

  bool _isJumping = false;
  bool _isPreloading = false;

  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _controller.addListener(_handleLoopScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _jumpToMiddle();
    });
  }

  @override
  void didUpdateWidget(covariant HomeVideosPlaylist oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.movies.length != widget.movies.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _jumpToMiddle();
      });
    }
  }

  void _jumpToMiddle() {
    if (!_controller.hasClients || widget.movies.isEmpty) return;

    if (!widget.infiniteLoop) {
      _controller.jumpTo(0);
      return;
    }

    final middleIndex = (widget.movies.length * _multiplier) ~/ 2;
    final middleOffset = middleIndex * _itemFullWidth;

    _controller.jumpTo(middleOffset);
  }

  void _handleLoopScroll() {
    if (!widget.infiniteLoop ||
        !_controller.hasClients ||
        widget.movies.isEmpty ||
        _isJumping) {
      return;
    }

    final offset = _controller.offset;
    final singleSetWidth = widget.movies.length * _itemFullWidth;
    final totalWidth = singleSetWidth * _multiplier;

    final middleIndex = (widget.movies.length * _multiplier) ~/ 2;
    final middleOffset = middleIndex * _itemFullWidth;

    const threshold = 200.0;

    if (offset <= threshold) {
      _jump(offset, singleSetWidth, middleOffset);
      return;
    }

    if (offset >= totalWidth - threshold) {
      _jump(offset, singleSetWidth, middleOffset);
      return;
    }
  }

  void _jump(double offset, double singleSetWidth, double middleOffset) {
    _isJumping = true;

    final normalizedOffset = offset % singleSetWidth;
    final targetOffset = middleOffset + normalizedOffset;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_controller.hasClients) {
        _controller.jumpTo(targetOffset);
      }
      _isJumping = false;
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_handleLoopScroll);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.movies.isEmpty) {
      return const SizedBox(height: 220);
    }

    final List<dynamic> displayList = widget.infiniteLoop
        ? List.generate(
            _multiplier,
            (_) => widget.movies,
          ).expand((e) => e).toList()
        : widget.movies;

    return SizedBox(
      height: 220,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            final metrics = notification.metrics;

            final current = metrics.pixels;
            final max = metrics.maxScrollExtent;

            if (current >= max * 0.8 &&
                !_isPreloading &&
                !widget.isLoading &&
                widget.hasMore) {
              _isPreloading = true;

              widget.onLoadMore(widget.playlistId).whenComplete(() {
                _isPreloading = false;
              });
            }
          }
          return false;
        },
        child: ListView.separated(
          controller: _controller,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: displayList.length,
          separatorBuilder: (context, index) =>
              const SizedBox(width: _separatorWidth),
          itemBuilder: (context, index) {
            return _MovieCard(item: displayList[index]);
          },
        ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  final dynamic item;

  const _MovieCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final Map<dynamic, dynamic>? movie = item is Map
        ? (item['movie'] as Map?)
        : null;

    final String title = movie != null
        ? (movie['title'] ?? '').toString()
        : (item is Map ? (item['title'] ?? '').toString() : '');

    final String posterUrl = movie != null
        ? (movie['poster'] ?? movie['banner'] ?? '').toString()
        : (item is Map
              ? (item['poster'] ?? item['banner'] ?? '').toString()
              : '');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            posterUrl,
            fit: BoxFit.cover,
            height: 180,
            width: 120,
            errorBuilder: (_, _, _) => Container(
              color: Colors.black12,
              height: 180,
              width: 120,
              child: const Icon(Icons.broken_image),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 120,
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
