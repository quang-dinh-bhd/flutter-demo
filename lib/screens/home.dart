import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../services/main_services.dart';
import '../widgets/home/home_hero_carousel.dart';
import '../widgets/home/home_menu_bar.dart';
import '../widgets/home/home_playlists.dart';

class HomePage extends StatefulWidget {
  final List<dynamic> menuItems;

  const HomePage({super.key, required this.menuItems});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const int _maxPlaylists = 5;
  static const int _playlistPageSize = 10;

  final MainServices _services = MainServices();
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  List<dynamic> _carouselList = [];
  bool _isLoadingCarousel = false;
  int _carouselIndex = 0;

  String _currentModuleId = '';
  List<dynamic> _playlists = [];
  bool _isLoadingPlaylists = false;

  final Map<String, List<dynamic>> _videosPlaylist = {};
  final Set<String> _loadingPlaylistMovies = {};
  final Map<String, int> _playlistPage = {};
  final Map<String, bool> _loadMore = {};
  final Set<String> _playlistInfiniteLoop = {};

  @override
  void initState() {
    super.initState();
    if (widget.menuItems.isNotEmpty) {
      _selectModule(_getModuleId(widget.menuItems[0]));
    }
  }

  String _cleanUrl(String url) => url.trim();

  String _getModuleId(dynamic menuItem) {
    return (menuItem is Map ? (menuItem['params']?['module_id']) : '')
        .toString();
  }

  Future<void> _getCarousel(String moduleId) async {
    if (moduleId.isEmpty) return;
    setState(() => _isLoadingCarousel = true);
    try {
      final results = await _services.getCarousel(moduleId);
      if (!mounted) return;
      setState(() {
        _carouselList = results;
        _isLoadingCarousel = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingCarousel = false);
      debugPrint("Lỗi tải carousel: ${e.toString()}");
    }
  }

  Future<void> _getPlaylists(String moduleId) async {
    if (moduleId.isEmpty) return;
    setState(() => _isLoadingPlaylists = true);
    try {
      final results = await _services.getPlaylists(moduleId);
      if (!mounted) return;
      setState(() {
        _playlists = results;
        _isLoadingPlaylists = false;
      });
      _playlistInfiniteLoop
        ..clear()
        ..addAll(
          results
              .whereType<Map>()
              .where((p) => (p['is_infinite_loop']?.toString() ?? '0') == '1')
              .map((p) => (p['id']?.toString() ?? ''))
              .where((id) => id.isNotEmpty),
        );
      _getVideosByPlaylistId(results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPlaylists = false);
      debugPrint("Lỗi tải playlists: ${e.toString()}");
    }
  }

  Future<void> _getVideosByPlaylistId(List<dynamic> playlists) async {
    for (final p in playlists) {
      final String id = p is Map ? (p['id']?.toString() ?? '') : '';
      if (id.isEmpty) continue;
      _playlistPage[id] = 1;
      _loadMore[id] = true;
      _fetchVideosForPlaylist(id, page: 1, append: false);
    }
  }

  Future<void> _fetchVideosForPlaylist(
    String playlistId, {
    required int page,
    required bool append,
  }) async {
    if (playlistId.isEmpty) return;
    if (_loadingPlaylistMovies.contains(playlistId)) return;
    _loadingPlaylistMovies.add(playlistId);
    if (mounted) setState(() {});
    try {
      final movies = await _services.getVideosByPlaylist(playlistId, page);
      if (!mounted) return;
      setState(() {
        if (append && _videosPlaylist[playlistId] != null) {
          _videosPlaylist[playlistId] = [
            ..._videosPlaylist[playlistId]!,
            ...movies,
          ];
        } else {
          _videosPlaylist[playlistId] = movies;
        }
        _loadMore[playlistId] = movies.length >= _playlistPageSize;
        _loadingPlaylistMovies.remove(playlistId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _videosPlaylist[playlistId] = const [];
        _loadMore[playlistId] = false;
        _loadingPlaylistMovies.remove(playlistId);
      });
    }
  }

  void _loadMoreForPlaylist(String playlistId) {
    if (playlistId.isEmpty) return;

    if (_loadingPlaylistMovies.contains(playlistId)) return;
    // false
    final hasMore = _loadMore[playlistId] ?? true;
    final infinite = _playlistInfiniteLoop.contains(playlistId);

    // if (!hasMore) {
    if (_videosPlaylist[playlistId] == null) {
      if (!infinite) return;
      _playlistPage[playlistId] = 1;
      _loadMore[playlistId] = true;
      _fetchVideosForPlaylist(playlistId, page: 1, append: false);
      return;
    }
    if (hasMore) {
      final nextPage = (_playlistPage[playlistId] ?? 1) + 1;
      _playlistPage[playlistId] = nextPage;
      _fetchVideosForPlaylist(playlistId, page: nextPage, append: true);
    }
  }

  void _selectModule(String moduleId) {
    if (moduleId.isEmpty) return;
    _currentModuleId = moduleId;
    _getCarousel(moduleId);
    _getPlaylists(moduleId);
  }

  void _selectModuleFromItem(dynamic item) {
    final String moduleId = _getModuleId(item);
    if (moduleId.isEmpty) return;
    setState(() {
      _carouselIndex = 0;
      _currentModuleId = moduleId;
      _carouselList = [];
      _playlists = [];
      _videosPlaylist.clear();
      _loadingPlaylistMovies.clear();
      _playlistPage.clear();
      _loadMore.clear();
      _playlistInfiniteLoop.clear();
    });
    _selectModule(moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final shownPlaylists = _playlists.length > _maxPlaylists
        ? _playlists.take(_maxPlaylists).toList()
        : _playlists;

    return Scaffold(
      appBar: AppBar(title: const Text("DANET")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            HomeMenuBar(
              menuItems: widget.menuItems,
              onSelectItem: _selectModuleFromItem,
            ),
            HomeHeroCarousel(
              isLoading: _isLoadingCarousel,
              items: _carouselList,
              currentIndex: _carouselIndex,
              controller: _carouselController,
              onIndexChanged: (i) => setState(() => _carouselIndex = i),
              normalizeImageUrl: _cleanUrl,
            ),
            HomePlaylists(
              isLoading: _isLoadingPlaylists,
              currentModuleId: _currentModuleId,
              playlists: shownPlaylists,
              playlistMovies: _videosPlaylist,
              loadingPlaylistMovies: _loadingPlaylistMovies,
              loadMore: _loadMore,
              onLoadMore: _loadMoreForPlaylist,
              normalizeImageUrl: _cleanUrl,
            ),
          ],
        ),
      ),
    );
  }
}
