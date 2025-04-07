import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';

import 'package:lumina/models/story_model.dart';
import 'package:lumina/services/firebase_service.dart'; // Add this import for Timer

class RevolvingStoriesDashboard extends StatefulWidget {
  @override
  _RevolvingStoriesDashboardState createState() => _RevolvingStoriesDashboardState();
}

class _RevolvingStoriesDashboardState extends State<RevolvingStoriesDashboard> with SingleTickerProviderStateMixin {
  late PageController _pageController;
  int _currentPage = 0; // Start with middle page
  double viewportFraction = 0.375; // Increased from 0.3 to 0.375 (1.25x wider)
  Timer? _autoScrollTimer; // Timer for auto scrolling
  
  List<Story> stories = []; // List of stories to be displayed
  bool isLoading = true; // Loading state

  // final List<StoryPanel> stories = [
  //   StoryPanel(
  //     title: "I faced discrimination",
  //     content: "I have experienced gender inequality at my job ever since I started working there...",
  //     country: "India",
  //   ),
  //   StoryPanel(
  //     title: "Gender pay gap",
  //     content: "Despite having the same qualifications, I was paid 30% less than my male colleagues...",
  //     country: "USA",
  //   ),
  //   StoryPanel(
  //     title: "Education denied",
  //     content: "My brothers were sent to school while I was expected to help with household chores...",
  //     country: "Afghanistan",
  //   ),
  // ];

  @override
  void initState() {
    super.initState();
    _loadRandomStories(); // Load random stories on initialization
    // Initialize with the middle page and add padding on sides to create the revolving effect
    _pageController = PageController(
      initialPage: _currentPage,
      viewportFraction: viewportFraction,
    );
    
    // Set up timer for auto scrolling every 5 seconds
    _autoScrollTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (_currentPage < stories.length - 1) {
        _pageController.animateToPage(
          _currentPage + 1,
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      } else {
        // Loop back to the first page when we reach the end
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
    _autoScrollTimer?.cancel(); // Cancel the timer when disposing the widget
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRandomStories() async {
    try {
      List<Map<String, dynamic>> results = await FirebaseService.getRandomStories(3);
      setState(() {
        stories = results.map((map) => Story.fromMap(map)).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error loading random stories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Title with gradient - changed to yellow-orange
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              Color(0xFFFFD700), // Bright Yellow
              Color(0xFFFF8C00), // Bright Orange
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: Text(
            "Top Stories",
            style: GoogleFonts.baloo2(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white, // The color that will be masked by gradient
            ),
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 35), // Increased from 20 to 35
        // Revolving panels
        Container(
          height: 210, // Increased from 120 to 210 (1.75x)
          child: isLoading
              ? Center(child: CircularProgressIndicator()) // Loading indicator while fetching stories
              :  PageView.builder(
                  controller: _pageController,
                  itemCount: stories.length,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemBuilder: (context, index) {
                    // Calculate scale factor for non-active pages
                    double value = 1.0;
                    if (_pageController.position.haveDimensions) {
                      value = index - _pageController.page!;
                      // Scale and opacity effects based on position
                      value = (1 - (value.abs() * 0.3)).clamp(0.8, 1.0);
                    } else {
                      // Apply initial scaling for panels before dimensions are available
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
                              ),
                              isActive: index == _currentPage,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
        SizedBox(height: 35), // Increased from 20 to 35
        // Navigation dots
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
      margin: EdgeInsets.symmetric(horizontal: 7), // Increased from 4 to 7
      height: 14, // Increased from 8 to 14
      width: isActive ? 42 : 14, // Increased from 24/8 to 42/14
      decoration: BoxDecoration(
        color: isActive 
            ? const Color(0xFFFF8C00) // Changed to bright orange
            : Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(7), // Increased from 4 to 7
      ),
    );
  }
}

class StoryPanel {
  final String title;
  final String content;
  final String country;

  StoryPanel({
    required this.title,
    required this.content,
    required this.country,
  });
}

class StoryPanelCard extends StatelessWidget {
  final StoryPanel panel;
  final bool isActive;

  const StoryPanelCard({
    Key? key,
    required this.panel,
    this.isActive = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 3), // Decreased from 4 to 3 to account for wider panels
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28), // Increased from 16 to 28
        border: Border.all(
          color: isActive ? Color(0xFFFF8C00).withOpacity(0.8) : Colors.transparent, // Changed to orange
          width: isActive ? 5 : 4, // Increased active border width for emphasis
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15), // Slightly stronger shadow
            blurRadius: 21, // Increased from 12 to 21
            offset: Offset(0, 7), // Increased from 0,4 to 0,7
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24), // Increased from 14 to 24
        child: Stack(
          children: [
            // Main card content
            Padding(
              padding: const EdgeInsets.all(20.0), // Increased from 12.0 to 20.0
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row with spotlight tag
                  Row(
                    children: [
                      Flexible(  // Added Flexible to handle text overflow in smaller width
                        child: Text(
                          '"${panel.title}"',
                          style: GoogleFonts.baloo2(
                            fontSize: 28,  // Increased from 16 to 28
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 7),  // Increased from 4 to 7
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),  // Increased padding
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFFFFD700), // Bright Yellow
                              Color(0xFFFF8C00), // Bright Orange
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(21), // Increased from 12 to 21
                        ),
                        child: Text(
                          "Today's Spotlight",
                          style: GoogleFonts.baloo2(
                            fontSize: 18,  // Increased from 10 to 18
                            color: Colors.white,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),  // Increased from 6 to 10
                  // Story content
                  Expanded(
                    child: Text(
                      panel.content,
                      style: GoogleFonts.baloo2(
                        fontSize: 23,  // Increased from 13 to 23
                        color: Colors.grey[600],
                      ),
                      maxLines: 3,  // Increased from 2 to 3 for better readability at larger size
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  // Country name in bottom right
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      panel.country,
                      style: GoogleFonts.baloo2(
                        fontSize: 21,  // Increased from 12 to 21
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF8C00), // Changed to orange
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}