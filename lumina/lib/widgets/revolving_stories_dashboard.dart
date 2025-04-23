import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:lumina/models/story_model.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/theme_tag.dart';

class RevolvingStoriesDashboard extends StatefulWidget {
  final String spotlightTheme; // New required parameter
  const RevolvingStoriesDashboard({Key? key, required this.spotlightTheme}) : super(key: key);
  
  @override
  _RevolvingStoriesDashboardState createState() => _RevolvingStoriesDashboardState();
}

class _RevolvingStoriesDashboardState extends State<RevolvingStoriesDashboard> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0; 
  double viewportFraction = 0.375; 
  Timer? _autoScrollTimer;
  
  List<Story> stories = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTopStories(); // Now load top stories by theme
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );
    
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentPage < stories.length - 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadTopStories() async {
    try {
      List<Map<String, dynamic>> results =
          await FirebaseService.getTopStoriesByTheme(widget.spotlightTheme, 3);
      setState(() {
        stories = results.map((map) => Story.fromMap(map)).toList();
        isLoading = false;
      });
      print('Loaded top stories for ${widget.spotlightTheme}: ${stories.length} stories');
    } catch (e) {
      print('Error loading top stories for ${widget.spotlightTheme}: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFFF8C00),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            "Top Stories",
            style: GoogleFonts.baloo2(
              fontSize: 36, // Updated font size to match home page headers
              fontWeight: FontWeight.bold,
              color: Colors.white, // This color is masked by the gradient
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 35),
        Container(
          height: 210,
          child: isLoading
              ? Center(child: CircularProgressIndicator())
              : PageView.builder(
                  controller: _pageController,
                  itemCount: stories.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = index - _pageController.page!;
                      value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                    } else {
                      double initialPage = _currentPage.toDouble();
                      value = index - initialPage;
                      value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                    }
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: value,
                            child: StoryPanelCard(
                              panel: StoryPanel(
                                title: stories[index].title,
                                content: stories[index].story,
                                country: stories[index].country,
                                likes: stories[index].likes, // Pass likes
                              ),
                              isActive: index == _currentPage,
                              spotlightTheme: widget.spotlightTheme, // Pass the spotlight theme
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        SizedBox(height: 35),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            stories.length,
            (index) => _buildDot(index == _currentPage),
          ),
        ),
      ],
    );
  }

  Widget _buildDot(bool isActive) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 7),
      height: 14,
      width: isActive ? 42 : 14,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFF8C00) : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(7),
      ),
    );
  }
}

class StoryPanel {
  final String title;
  final String content;
  final String country;
  final int likes; // New field

  StoryPanel({
    required this.title,
    required this.content,
    required this.country,
    required this.likes, // New required parameter
  });
}

class StoryPanelCard extends StatelessWidget {
  final StoryPanel panel;
  final bool isActive;
  final String spotlightTheme; // New parameter

  const StoryPanelCard({
    Key? key,
    required this.panel,
    this.isActive = false,
    required this.spotlightTheme, // Require spotlightTheme
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/explore',
          arguments: {'applySpotlightFilter': true},
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isActive ? Color(0xFFFF8C00).withOpacity(0.8) : Colors.transparent,
            width: isActive ? 5 : 4,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 21,
              offset: Offset(0, 7),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            '"${panel.title}"',
                            style: GoogleFonts.baloo2(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Transform.scale(
                          scale: 1.2, // Increase scale to make the tag a bit bigger
                          child: ThemeTag(
                            theme: spotlightTheme,
                            currentSpotlight: spotlightTheme, // Pass the current spotlight theme value consistently
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      panel.content,
                      style: GoogleFonts.baloo2(
                        fontSize: 23,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2, // increased from 1 to 4 for a longer preview
                      overflow: TextOverflow.ellipsis,
                    ),
                    Spacer(),
                    // Bottom row: likes at left, country at right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${panel.likes}',
                              style: GoogleFonts.baloo2(
                                fontSize: 20,
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.favorite,
                              color: Colors.red,
                              size: 24,
                            ),
                          ],
                        ),
                        Text(
                          panel.country,
                          style: GoogleFonts.baloo2(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF8C00),
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
    );
  }
}