import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';

class TopStoriesDashboard extends StatefulWidget {
  @override
  _TopStoriesDashboardState createState() => _TopStoriesDashboardState();
}

class _TopStoriesDashboardState extends State<TopStoriesDashboard> {
  late PageController _pageController;
  int _currentPage = 0;
  final List<Map<String, String>> topStories = [
    {
      "title": "Story 1",
      "subtitle": "Unearthing systemic inequality in urban areas."
    },
    {
      "title": "Story 2",
      "subtitle": "A deep dive into education disparities."
    },
    {
      "title": "Story 3",
      "subtitle": "Health inequality in rural regions."
    },
  ];

  @override
  void initState() {
    super.initState();
    // Set viewportFraction to (panelWidth - overlap) / screenWidth.
    // Here, panelWidth is 0.25 of screen width and we want 25% overlap,
    // so viewportFraction = 0.25 * (1 - 0.25) = 0.1875.
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: 0.1875,
    );
    // Auto-scroll every 5 seconds.
    Future.delayed(Duration(seconds: 5), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    _currentPage = (_currentPage + 1) % topStories.length;
    _pageController.animateToPage(
      _currentPage,
      duration: Duration(milliseconds: 800),
      curve: Curves.easeInOut,
    );
    Future.delayed(Duration(seconds: 5), _autoScroll);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Each panel is 25% of screen width.
    final double panelWidth = screenWidth * 0.25;
    return Container(
      // Increased height to accommodate the title.
      height: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            "Top Stories",
            style: GoogleFonts.baloo2(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 255, 102, 0),
            ),
          ),
          SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: topStories.length,
              itemBuilder: (context, index) {
                return AnimatedBuilder(
                  animation: _pageController,
                  builder: (context, child) {
                    double value = 0;
                    if (_pageController.position.haveDimensions) {
                      value = _pageController.page! - index;
                    } else {
                      value = (_currentPage - index).toDouble();
                    }
                    double scale = max(0.8, 1 - value.abs() * 0.2);
                    double opacity = scale.clamp(0.8, 1.0);
                    return Align(
                      // Align left to allow panels to extend right and overlap.
                      alignment: Alignment.centerLeft,
                      child: Opacity(
                        opacity: opacity,
                        child: Transform.scale(
                          scale: scale,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    width: panelWidth,
                    margin: EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color.fromARGB(255, 255, 102, 0),
                          width: 2),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          topStories[index]["title"]!,
                          style: GoogleFonts.baloo2(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: const Color.fromARGB(255, 255, 102, 0),
                          ),
                        ),
                        SizedBox(height: 12),
                        Text(
                          topStories[index]["subtitle"]!,
                          style: GoogleFonts.baloo2(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}