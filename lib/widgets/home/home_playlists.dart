import 'package:flutter/material.dart';
import '../../models/playlist_model.dart';
import '../../services/main_services.dart';
import 'home_videos_playlist.dart';

enum LoadState { initial, loading, loadingMore, success, empty, end, error }

class HomePlaylists extends StatefulWidget {
  static const int maxPlaylists = 5;
  final String moduleId;

  const HomePlaylists({super.key, required this.moduleId});

  @override
  PlaylistsState createState() => PlaylistsState();
}

class PlaylistsState extends State<HomePlaylists> {
  final MainServices _services = MainServices();

  LoadState _state = LoadState.initial;
  int _page = 1;
  List<PlaylistModel> _playlists = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaylists();
  }

  @override
  void didUpdateWidget(covariant HomePlaylists oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId) {
      _reset();
      _fetchPlaylists();
    }
  }

  void _reset() {
    setState(() {
      _state = LoadState.initial;
      _page = 1;
      _playlists = [];
    });
  }

  void loadMore() {
    if (_state == LoadState.end ||
        _state == LoadState.loading ||
        _state == LoadState.loadingMore) {
      return;
    }

    _fetchPlaylists(append: true);
  }

  Future<void> _fetchPlaylists({bool append = false}) async {
    if (widget.moduleId.isEmpty) return;
    if (append && _state == LoadState.end) return;
    if (_state == LoadState.loadingMore) return;

    final currentModule = widget.moduleId;
    const int pageLimit = 10;

    if (!append) {
      setState(() {
        _state = LoadState.loading;
        _page = 1;
        _playlists = [];
      });
    } else {
      setState(() {
        _state = LoadState.loadingMore;
      });
    }

    try {
      final page = append ? _page : 1;
      final results = await _services.getPlaylists(
        currentModule,
        page: page,
        limit: pageLimit,
      );

      final newItems = results.map<PlaylistModel>((p) {
        return PlaylistModel(
          id: p['id'].toString(),
          name: (p['name'] ?? p['title'] ?? '').toString(),
          infiniteLoop: (p['is_infinite_loop']?.toString() ?? '0') == '1',
        );
      }).toList();

      setState(() {
        _playlists = append ? [..._playlists, ...newItems] : newItems;
        _page = page + 1;

        if (!append) {
          if (newItems.isEmpty) {
            _state = LoadState.empty;
          } else {
            _state = newItems.length >= pageLimit
                ? LoadState.success
                : LoadState.end;
          }
        } else {
          _state = newItems.length >= pageLimit
              ? LoadState.success
              : LoadState.end;
        }
      });

      for (final p in newItems) {
        await _fetchVideos(p);
      }
    } catch (e) {
      if (!mounted || widget.moduleId != currentModule) return;
      setState(() => _state = append ? LoadState.end : LoadState.error);
    }
  }

  Future<void> _fetchVideos(
    PlaylistModel playlist, {
    bool append = false,
  }) async {
    if (playlist.isLoadingMovies || !playlist.hasMore) return;

    setState(() {
      playlist.isLoadingMovies = true;
    });

    try {
      final movies = await _services.getVideos(
        playlist.id,
        page: playlist.page,
        limit: 10,
      );

      setState(() {
        playlist.movies = append ? [...playlist.movies, ...movies] : movies;
        playlist.page++;
        playlist.hasMore = movies.length >= 10;
        playlist.isLoadingMovies = false;
      });
    } catch (e) {
      setState(() {
        playlist.isLoadingMovies = false;
        playlist.hasMore = false;
      });
    }
  }

  Future<void> _loadMore(String id) async {
    final playlist = _playlists.firstWhere(
      (e) => e.id == id,
      orElse: () => PlaylistModel(id: '', name: ''),
    );

    if (playlist.id.isEmpty) return;

    await _fetchVideos(playlist, append: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_state == LoadState.loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.moduleId.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Nội dung chính")),
      );
    }

    if (_state == LoadState.empty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Không có playlist")),
      );
    }

    if (_state == LoadState.error) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Có lỗi xảy ra")),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: _playlists.length,
      separatorBuilder: (context, index) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        final p = _playlists[index];

        return _PlaylistSection(
          playlist: p,
          movies: p.movies,
          isLoadingMovies: p.isLoadingMovies,
          infiniteLoop: p.infiniteLoop,
          hasMore: p.hasMore,
          onLoadMore: _loadMore,
        );
      },
    );
  }
}

class _PlaylistSection extends StatelessWidget {
  final PlaylistModel playlist;
  final List<dynamic> movies;
  final bool isLoadingMovies;
  final bool infiniteLoop;
  final bool hasMore;
  final Future<void> Function(String) onLoadMore;

  const _PlaylistSection({
    required this.playlist,
    required this.movies,
    required this.isLoadingMovies,
    required this.infiniteLoop,
    required this.hasMore,
    required this.onLoadMore,
  });

  @override
  Widget build(BuildContext context) {
    final id = playlist.id;
    final name = playlist.name;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),

        if (isLoadingMovies && movies.isEmpty)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),

        if (movies.isNotEmpty)
          HomeVideosPlaylist(
            playlistId: id,
            infiniteLoop: infiniteLoop,
            isLoading: isLoadingMovies,
            hasMore: hasMore,
            movies: movies,
            onLoadMore: onLoadMore,
          ),
      ],
    );
  }
}
