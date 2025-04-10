import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/theme_tag.dart';
import 'widgets/navbar.dart';
import 'services/algolia_service.dart';
import 'models/story_model.dart';

class NoScrollbarBehavior extends ScrollBehavior {
  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class ExplorePage extends StatefulWidget {
  @override
  _ExplorePageState createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  List<Story> stories = [];
  bool isLoading = true;
  String searchQuery = '';
  String? selectedTheme;
  String? selectedCountry;
  
  final TextEditingController searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _loadStories();
  }
  
  Future<void> _loadStories() async {
    setState(() {
      isLoading = true;
    });
    
    try {
      List<Map<String, dynamic>> results;
      
      if (searchQuery.isNotEmpty || selectedTheme != null || selectedCountry != null) {
        results = await AlgoliaService.searchWithFilters(
          query: searchQuery,
          theme: selectedTheme,
          country: selectedCountry,
        );
      } else {
        // Just get all stories
        results = await AlgoliaService.searchStories('');
      }
      
      setState(() {
        stories = results.map((map) => Story.fromMap(map)).toList();
        isLoading = false;
      });
      print('Loaded ${stories.length} stories');
    } catch (e) {
      print('Error loading stories: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _search() {
    _loadStories();
  }
  
  void _showFilterOptions() {
    // Implement filter dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Stories'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Theme dropdown
            DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select Theme'),
              value: selectedTheme,
              items: ['Workplace', 'Domestic', 'Educational', 'Healthcare', 'Public Space', 'Other', null]
                  .map((theme) => DropdownMenuItem(
                        value: theme,
                        child: Text(theme ?? 'All Themes'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedTheme = value;
                });
              },
            ),
            SizedBox(height: 16),
            // Country dropdown
            DropdownButton<String>(
              isExpanded: true,
              hint: Text('Select Country'),
              value: selectedCountry,
              items: ['India', 'Saudi Arabia', 'United States', 'Other', null]
                  .map((country) => DropdownMenuItem(
                        value: country,
                        child: Text(country ?? 'All Countries'),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedCountry = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _loadStories();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'explore'),
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 60, left: 16, right: 16),
          child: Column(
            children: [
              // Search bar and filter
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: 'Search stories...',
                          prefixIcon: Icon(Icons.search),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                        },
                        onSubmitted: (_) => _search(),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Container(
                    height: 50,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.tune),
                      onPressed: _showFilterOptions,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              // Story list
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator())
                    : stories.isEmpty
                        ? Center(child: Text('No stories found'))
                        : ScrollConfiguration(
                            behavior: NoScrollbarBehavior(),
                            child: ListView.builder(
                              itemCount: stories.length,
                              itemBuilder: (context, index) {
                                final story = stories[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: ExpandableStoryCard(
                                    storyId: story.id,
                                    title: story.title,
                                    themes: story.themes.isNotEmpty ? story.themes : ['Other'],
                                    country: story.country,
                                    shortContent: story.story.length > 100
                                        ? '${story.story.substring(0, 100)}...'
                                        : story.story,
                                    fullContent: story.story,
                                    likes: story.likes,
                                  ),
                                );
                              },
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Color _getThemeColor(String theme) {
    switch (theme) {
      case 'Workplace':
        return Colors.red;
      case 'Domestic':
        return Colors.purple;
      case 'Educational':
        return Colors.blue;
      case 'Healthcare':
        return Colors.green;
      case 'Public Space':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

class ExpandableStoryCard extends StatefulWidget {
  final String storyId;
  final String title;
  final List<String> themes;
  final String country;
  final String shortContent;
  final String fullContent;
  final int likes;

  const ExpandableStoryCard({
    Key? key,
    required this.storyId,
    required this.title,
    required this.themes,
    required this.country,
    required this.shortContent,
    required this.fullContent,
    required this.likes,
  }) : super(key: key);

  @override
  _ExpandableStoryCardState createState() => _ExpandableStoryCardState();
}

class _ExpandableStoryCardState extends State<ExpandableStoryCard> {
  bool _isExpanded = false;
  bool _isHovering = false;
  bool _isLiked = false;
  late int _likeCount;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.likes;
  }

  void _toggleLike() async {
    setState(() {
      if (_isLiked) {
        _likeCount--;
      } else {
        _likeCount++;
      }
      _isLiked = !_isLiked;
    });
    
    try {
      await FirebaseService.updateLikes(widget.storyId, _likeCount);
    } catch (e) {
      print('Error updating likes: $e');
      setState(() {
        if (_isLiked) {
          _likeCount--;
        } else {
          _likeCount++;
        }
        _isLiked = !_isLiked;
      });
    }
  }

  // Returns a list of border colors based on the story's themes using the mapping from ThemeTag.
  List<Color> _getBorderColors() {
    return widget.themes.map((tag) => ThemeTag.getColor(tag)).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Capture the content of the card without any external border decoration.
    Widget cardContent = AnimatedContainer(
      duration: Duration(milliseconds: 200),
      transform: _isHovering && !_isExpanded
          ? Matrix4.translationValues(0, -5, 0)
          : Matrix4.translationValues(0, 0, 0),
      // Note: No border here—this will be applied via a wrapper if needed.
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isHovering || _isExpanded
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                )
              ]
            : [],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Title and theme tags
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        '"${widget.title}"',
                        style: GoogleFonts.baloo2(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Wrap(
                        spacing: 4,
                        children: widget.themes
                            .map((tag) => ThemeTag(theme: tag))
                            .toList(),
                      ),
                    ],
                  ),
                ),
                // Country name
                Text(
                  widget.country,
                  style: GoogleFonts.baloo2(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            // Story content
            Text(
              _isExpanded ? widget.fullContent : widget.shortContent,
              style: GoogleFonts.baloo2(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            // Like counter
            Align(
              alignment: Alignment.bottomRight,
              child: _isExpanded
                  ? GestureDetector(
                      onTap: _toggleLike,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_likeCount',
                            style: GoogleFonts.baloo2(
                              fontSize: 20,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            _isLiked ? Icons.favorite : Icons.favorite_outline,
                            color: Colors.red,
                            size: 24,
                          ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.likes}',
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
            ),
          ],
        ),
      ),
    );

    // Determine the border decoration based on the number of theme colors.
    List<Color> borderColors = _getBorderColors();
    if (borderColors.length >= 2) {
      // Use a gradient border if two or more themes exist.
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [borderColors[0], borderColors[1]]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              margin: EdgeInsets.all(2), // Border width
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: cardContent,
            ),
          ),
        ),
      );
    } else {
      // Use a single solid border if only one theme is present.
      return MouseRegion(
        onEnter: (_) => setState(() => _isHovering = true),
        onExit: (_) => setState(() => _isHovering = false),
        child: GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: AnimatedContainer(
            duration: Duration(milliseconds: 200),
            transform: _isHovering && !_isExpanded
                ? Matrix4.translationValues(0, -5, 0)
                : Matrix4.translationValues(0, 0, 0),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(
                  color: borderColors.isNotEmpty ? borderColors.first : Colors.grey,
                  width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _isHovering || _isExpanded
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: Offset(0, 3),
                      )
                    ]
                  : [],
            ),
            child: cardContent,
          ),
        ),
      );
    }
  }
}