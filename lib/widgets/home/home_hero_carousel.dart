import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class HomeHeroCarousel extends StatelessWidget {
  final bool isLoading;
  final List<dynamic> items;
  final int currentIndex;
  final CarouselSliderController controller;
  final ValueChanged<int> onIndexChanged;
  final String Function(String url) normalizeImageUrl;

  const HomeHeroCarousel({
    super.key,
    required this.isLoading,
    required this.items,
    required this.currentIndex,
    required this.controller,
    required this.onIndexChanged,
    required this.normalizeImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (items.isEmpty) {
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
            carouselController: controller,
            options: CarouselOptions(
              viewportFraction: 1.0,
              height: bannerHeight,
              autoPlay: true,
              enlargeCenterPage: false,
              enableInfiniteScroll: true,
              pageSnapping: true,
              onPageChanged: (index, reason) => onIndexChanged(index),
            ),
            items: items.map<Widget>(_buildSlide).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSlide(dynamic item) {
    final dynamic rawUrl = item is Map ? item['vertical_banner'] : item;
    final String imageUrl = normalizeImageUrl((rawUrl ?? '').toString());

    final String title = item is Map ? (item['title'] ?? '').toString() : '';
    final String description = item is Map
        ? ((item['description'] ?? '') as String).replaceAll('\uFFFD', '')
        : '';

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
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 120, 32, 80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (title.isNotEmpty)
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              const SizedBox(height: 12),
              if (quality.isNotEmpty ||
                  qualifier.isNotEmpty ||
                  year.isNotEmpty ||
                  episodes.isNotEmpty)
                Row(
                  children: [
                    if (quality.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white54),
                        ),
                        child: Text(
                          quality,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (qualifier.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF74B13A),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          qualifier,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    if (year.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 18),
                        child: Text(
                          year,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (episodes.isNotEmpty)
                      Text(
                        '$episodes tập',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              const SizedBox(height: 16),
              if (description.isNotEmpty)
                Text(
                  description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              const SizedBox(height: 24),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
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
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  'Xem ngay',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
