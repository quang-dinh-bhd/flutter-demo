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
    return _HomePage(menuItems: menuItems, initialModuleId: initialModuleId);
  }
}

class _HomePage extends StatefulWidget {
  final List<dynamic> menuItems;
  final String initialModuleId;

  const _HomePage({required this.menuItems, required this.initialModuleId});

  @override
  State<_HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<_HomePage> {
  final GlobalKey<PlaylistsState> _playlistsKey = GlobalKey<PlaylistsState>();
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

  void _setModuleId(dynamic item) {
    final String moduleId = _getModuleId(item);
    if (moduleId.isEmpty) return;
    setState(() {
      _currentModuleId = moduleId;
    });
  }

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
              _playlistsKey.currentState?.loadMore();
            }
          }
          return false;
        },
        child: SingleChildScrollView(
          child: Column(
            children: [
              HomeMenuBar(
                menuItems: widget.menuItems,
                onSelectItem: _setModuleId,
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
