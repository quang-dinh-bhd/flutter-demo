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
  final MainServices _services = MainServices();
  final CarouselSliderController _carouselController =
      CarouselSliderController();

  Map<String, dynamic> _data = {
    'carouselList': [],
    'playlists': [],
    'videosPlaylist': <String, List<dynamic>>{},
    'loadingPlaylistMovies': <String>{},
    'playlistPage': <String, int>{},
    'loadMore': <String, bool>{},
    'playlistInfiniteLoop': <String>{},
    'currentModuleId': '',
  };
  int _carouselIndex = 0;
  bool _isLoading = false;

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
    setState(() => _isLoading = true);
    try {
      final results = await _services.getCarousel(moduleId, page: 1, limit: 20);
      if (!mounted) return;
      setState(() {
        _data['carouselList'] = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải carousel: \\${e.toString()}");
    }
  }

  Future<void> _getPlaylists(String moduleId) async {
    if (moduleId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await _services.getPlaylists(moduleId);
      if (!mounted) return;
      setState(() {
        _data['playlists'] = results;
        _isLoading = false;
        _data['playlistInfiniteLoop'] = results
            .whereType<Map>()
            .where((p) => (p['is_infinite_loop']?.toString() ?? '0') == '1')
            .map((p) => (p['id']?.toString() ?? ''))
            .where((id) => id.isNotEmpty)
            .toSet();
      });
      _getVideosByPlaylistId(results);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải playlists: \\${e.toString()}");
    }
  }

  Future<void> _getVideosByPlaylistId(List<dynamic> playlists) async {
    for (final p in playlists) {
      final String id = p is Map ? (p['id']?.toString() ?? '') : '';
      if (id.isEmpty) continue;
      _data['playlistPage'][id] = 1;
      _data['loadMore'][id] = true;
      _fetchVideosForPlaylist(id, page: 1, append: false);
    }
  }

  Future<void> _fetchVideosForPlaylist(
    String playlistId, {
    required int page,
    required bool append,
  }) async {
    if (playlistId.isEmpty) return;
    if (_data['loadingPlaylistMovies'].contains(playlistId)) return;
    _data['loadingPlaylistMovies'].add(playlistId);
    if (mounted) setState(() {});
    try {
      final movies = await _services.getVideosByPlaylist(playlistId, page);
      if (!mounted) return;
      setState(() {
        if (append && _data['videosPlaylist'][playlistId] != null) {
          _data['videosPlaylist'][playlistId] = [
            ..._data['videosPlaylist'][playlistId]!,
            ...movies,
          ];
        } else {
          _data['videosPlaylist'][playlistId] = movies;
        }
        _data['loadMore'][playlistId] = movies.length >= 10;
        _data['loadingPlaylistMovies'].remove(playlistId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _data['videosPlaylist'][playlistId] = const [];
        _data['loadMore'][playlistId] = false;
        _data['loadingPlaylistMovies'].remove(playlistId);
      });
    }
  }

  Future<void> _loadMoreForPlaylist(String playlistId) async {
    if (playlistId.isEmpty) return;
    if (_data['loadingPlaylistMovies'].contains(playlistId)) return;
    final hasMore = _data['loadMore'][playlistId] ?? true;
    final infinite = _data['playlistInfiniteLoop'].contains(playlistId);
    if (_data['videosPlaylist'][playlistId] == null) {
      if (!infinite) return;
      _data['playlistPage'][playlistId] = 1;
      _data['loadMore'][playlistId] = true;
      _fetchVideosForPlaylist(playlistId, page: 1, append: false);
      return;
    }
    if (hasMore) {
      final nextPage = (_data['playlistPage'][playlistId] ?? 1) + 1;
      _data['playlistPage'][playlistId] = nextPage;
      _fetchVideosForPlaylist(playlistId, page: nextPage, append: true);
    }
  }

  void _selectModule(String moduleId) {
    if (moduleId.isEmpty) return;
    _data['currentModuleId'] = moduleId;
    _getCarousel(moduleId);
    _getPlaylists(moduleId);
  }

  void _selectModuleFromItem(dynamic item) {
    final String moduleId = _getModuleId(item);
    if (moduleId.isEmpty) return;
    setState(() {
      _carouselIndex = 0;
      _data['currentModuleId'] = moduleId;
      _data['carouselList'] = [];
      _data['playlists'] = [];
      _data['videosPlaylist'].clear();
      _data['loadingPlaylistMovies'].clear();
      _data['playlistPage'].clear();
      _data['loadMore'].clear();
      _data['playlistInfiniteLoop'].clear();
    });
    _selectModule(moduleId);
  }

  @override
  Widget build(BuildContext context) {
    final shownPlaylists = (_data['playlists'] as List).length > _maxPlaylists
        ? (_data['playlists'] as List).take(_maxPlaylists).toList()
        : _data['playlists'];

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
              isLoading: _isLoading,
              items: _data['carouselList'],
              currentIndex: _carouselIndex,
              controller: _carouselController,
              onIndexChanged: (i) => setState(() => _carouselIndex = i),
              normalizeImageUrl: _cleanUrl,
            ),
            HomePlaylists(
              isLoading: _isLoading,
              currentModuleId: _data['currentModuleId'],
              playlists: shownPlaylists,
              playlistMovies: _data['videosPlaylist'],
              loadingPlaylistMovies: _data['loadingPlaylistMovies'],
              loadMore: _data['loadMore'],
              onLoadMore: _loadMoreForPlaylist,
              normalizeImageUrl: _cleanUrl,
            ),
          ],
        ),
      ),
    );
  }
}
