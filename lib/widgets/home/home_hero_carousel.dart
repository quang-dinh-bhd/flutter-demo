import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../services/main_services.dart';

class HomeHeroCarousel extends StatefulWidget {
  final String moduleId;

  const HomeHeroCarousel({super.key, required this.moduleId});

  @override
  State<HomeHeroCarousel> createState() => _HomeHeroCarouselState();
}

class _HomeHeroCarouselState extends State<HomeHeroCarousel> {
  final MainServices _services = MainServices();
  final CarouselSliderController _controller = CarouselSliderController();

  bool _isLoading = false;
  List<dynamic> _items = const [];

  @override
  void initState() {
    super.initState();
    _getData();
  }

  @override
  void didUpdateWidget(covariant HomeHeroCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.moduleId != widget.moduleId) {
      _items = const [];
      _getData();
    }
  }

  Future<void> _getData() async {
    final moduleId = widget.moduleId;
    if (moduleId.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final results = await _services.getCarousel(moduleId, page: 1, limit: 10);
      if (!mounted) return;
      setState(() {
        _items = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      debugPrint("Lỗi tải carousel: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moduleId.isEmpty) {
      return const SizedBox(height: 100);
    }

    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_items.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(child: Text("Không có dữ liệu banner")),
      );
    }

    final size = MediaQuery.of(context).size;
    final bannerHeight = size.width * 9 / 10;

    return SizedBox(
      width: size.width,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CarouselSlider(
            carouselController: _controller,
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: bannerHeight,
              autoPlay: true,
              enlargeCenterPage: false,
              enableInfiniteScroll: true,
              pageSnapping: true,
              onPageChanged: (index, reason) {},
            ),
            items: _items.map<Widget>(_buildSlide).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(dynamic item) {
    final dynamic rawUrl = item is Map ? item['vertical_banner'] : item;
    final String imageUrl = rawUrl.toString();

    final String title = item is Map ? (item['title'] ?? '').toString() : '';

    final Map<dynamic, dynamic>? movie = item is Map
        ? (item['movie'] as Map?)
        : null;
    final String year = movie != null
        ? (movie['release_year']?.toString() ?? '')
        : '';
    final String episodes = movie != null
        ? (movie['total_episodes']?.toString() ?? '')
        : '';
    final String quality = movie != null
        ? (movie['quality'] ?? '').toString()
        : '';
    final String qualifier = movie != null
        ? (movie['qualifier'] ?? '').toString()
        : '';

    return Stack(
      fit: StackFit.expand,
      children: [
        imageUrl.isNotEmpty
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image)),
              )
            : const ColoredBox(color: Colors.black54),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Colors.black87, Colors.black54, Colors.transparent],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 120,
            padding: const EdgeInsets.fromLTRB(24, 10, 24, 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [Colors.black87, Colors.transparent],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title.isNotEmpty)
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  if (quality.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.white54,
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        quality,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  if (qualifier.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF74B13A),
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        child: Text(
                                          qualifier,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (year.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        year,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  if (episodes.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Text(
                                        '$episodes tập',
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                            onPressed: () {
                              debugPrint('Xem ngay: $title');
                            },
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: const Text(
                              'Xem ngay',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
