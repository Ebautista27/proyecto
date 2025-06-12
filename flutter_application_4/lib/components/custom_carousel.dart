import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:carousel_slider/carousel_controller.dart' as cs;

class CustomCarousel extends StatefulWidget {
  final List<String> imageAssets;
  final double height;
  final bool autoPlay;
  final double viewportFraction;

  const CustomCarousel({
    super.key,
    required this.imageAssets,
    this.height = 250,
    this.autoPlay = true,
    this.viewportFraction = 0.85,
  });

  @override
  State<CustomCarousel> createState() => _CustomCarouselState();
}

class _CustomCarouselState extends State<CustomCarousel> {
  late final cs.CarouselController _controller;

  @override
  void initState() {
    super.initState();
    _controller = cs.CarouselController();
  }

  @override
  Widget build(BuildContext context) {
    return CarouselSlider(
      items: widget.imageAssets.map((assetPath) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => const Icon(Icons.error),
                ),
              ),
            );
          },
        );
      }).toList(),
      options: CarouselOptions(
        height: widget.height,
        viewportFraction: widget.viewportFraction,
        autoPlay: widget.autoPlay,
        enlargeCenterPage: true,
      ),
      carouselController: _controller, // Aquí lo usamos correctamente
    );
  }
}
