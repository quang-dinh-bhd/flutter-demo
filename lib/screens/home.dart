import 'package:flutter/material.dart';

import '../widgets/home/home_hero_carousel.dart';
import '../widgets/home/home_menu_bar.dart';
import '../widgets/home/home_playlists.dart';

String _getModuleId(dynamic menuItem) {
  return (menuItem is Map ? (menuItem['params']?['module_id']) : '').toString();
}

class HomePage extends StatelessWidget {
  final List<dynamic> menuItems;

  const HomePage({super.key, required this.menuItems});

  @override
  Widget build(BuildContext context) {
    final initialModuleId = menuItems.isNotEmpty
        ? _getModuleId(menuItems[0])
        : '';
    return _HomePageScaffold(
      menuItems: menuItems,
      initialModuleId: initialModuleId,
    );
  }
}

class _HomePageScaffold extends StatefulWidget {
  final List<dynamic> menuItems;
  final String initialModuleId;

  const _HomePageScaffold({
    required this.menuItems,
    required this.initialModuleId,
  });

  @override
  State<_HomePageScaffold> createState() => _HomePageScaffoldState();
}

class _HomePageScaffoldState extends State<_HomePageScaffold> {
  final GlobalKey<HomePlaylistsState> _playlistsKey =
      GlobalKey<HomePlaylistsState>();
  late String _currentModuleId;

  @override
  void initState() {
    super.initState();
    _currentModuleId = widget.initialModuleId;
  }

  String _getModuleId(dynamic menuItem) {
    return (menuItem is Map ? (menuItem['params']?['module_id']) : '')
        .toString();
  }

  void _selectModuleFromItem(dynamic item) {
    final String moduleId = _getModuleId(item);
    if (moduleId.isEmpty) return;
    setState(() {
      _currentModuleId = moduleId;
    });
  }

  Duration _debounceDuration = const Duration(milliseconds: 500);
  DateTime _lastLoadMore = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("DANET")),
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification &&
              notification.metrics.axis == Axis.vertical) {
            final current = notification.metrics.pixels;
            final max = notification.metrics.maxScrollExtent;
            if (current >= max * 0.8) {
              final now = DateTime.now();
              if (now.difference(_lastLoadMore) > _debounceDuration) {
                _lastLoadMore = now;
                _playlistsKey.currentState?.loadMore();
              }
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeMenuBar(
                menuItems: widget.menuItems,
                onSelectItem: _selectModuleFromItem,
              ),
              HomeHeroCarousel(moduleId: _currentModuleId),
              HomePlaylists(key: _playlistsKey, moduleId: _currentModuleId),
            ],
          ),
        ),
      ),
    );
  }
}
