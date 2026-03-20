import 'package:flutter/material.dart';
import '../../models/playlist_model.dart';
import '../../services/main_services.dart';
import 'home_videos_playlist.dart';

class HomePlaylists extends StatefulWidget {
  static const int maxPlaylists = 5;
  final String moduleId;

  const HomePlaylists({super.key, required this.moduleId});

  @override
  HomePlaylistsState createState() => HomePlaylistsState();
}

class HomePlaylistsState extends State<HomePlaylists> {
  final MainServices _services = MainServices();

  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMorePlaylists = true;
  int _nextPlaylistsPage = 1;
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
      _isLoading = false;
      _isLoadingMore = false;
      _hasMorePlaylists = true;
      _nextPlaylistsPage = 1;
      _playlists = [];
    });
  }

  void loadMore() {
    if (!_hasMorePlaylists || _isLoadingMore || _isLoading) return;
    _fetchPlaylists(append: true);
  }

  Future<void> _fetchPlaylists({bool append = false}) async {
    if (widget.moduleId.isEmpty || !_hasMorePlaylists && append) return;
    if (_isLoadingMore) return;

    if (!append) {
      setState(() {
        _isLoading = true;
        _hasMorePlaylists = true;
        _nextPlaylistsPage = 1;
        _playlists = [];
      });
    }

    _isLoadingMore = true;

    const int pageLimit = 10;
    try {
      final page = append ? _nextPlaylistsPage : 1;
      final results = await _services.getPlaylists(
        widget.moduleId,
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
        if (append) {
          _playlists.addAll(newItems);
        } else {
          _playlists = newItems;
        }

        _isLoading = false;
        _nextPlaylistsPage = page + 1;
        _hasMorePlaylists = newItems.length >= pageLimit;
      });

      for (final p in newItems) {
        _fetchVideos(p);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasMorePlaylists = false;
      });
    }

    _isLoadingMore = false;
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
      final movies = await _services.getVideosByPlaylist(
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

  Future<void> _loadMoreVideos(String id) async {
    final playlist = _playlists.firstWhere(
      (e) => e.id == id,
      orElse: () => PlaylistModel(id: '', name: ''),
    );

    if (playlist.id.isEmpty) return;

    await _fetchVideos(playlist, append: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
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

    if (_playlists.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: Text("Không có playlist")),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: _playlists.length,
      separatorBuilder: (_, __) => const SizedBox(height: 28),
      itemBuilder: (context, index) {
        final p = _playlists[index];

        return _PlaylistSection(
          playlist: p,
          movies: p.movies,
          isLoadingMovies: p.isLoadingMovies,
          infiniteLoop: p.infiniteLoop,
          hasMore: p.hasMore,
          onLoadMore: _loadMoreVideos,
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
