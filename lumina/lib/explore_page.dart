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
  
  // Update these to handle multiple selections
  List<String> selectedThemes = [];
  List<String> selectedCountries = [];
  
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
      
      if (searchQuery.isNotEmpty || selectedThemes.isNotEmpty || selectedCountries.isNotEmpty) {
        results = await AlgoliaService.searchWithMultipleFilters(
          query: searchQuery,
          themes: selectedThemes,
          countries: selectedCountries,
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
    // Define available themes including Cultural and Identity
    List<String> allThemes = [
      'Workplace', 
      'Domestic', 
      'Education', 
      'Healthcare', 
      'Public Space', 
      'Cultural', 
      'Identity', 
      'Other'
    ];
    List<String> allCountries = [
      'United States', 'India', 'Russia', 'China', 'Japan', 
      'United Kingdom', 'Canada', 'Australia', 'Brazil', 'Mexico', 
      'Germany', 'France', 'Italy', 'Spain', 'Saudi Arabia'
    ];
    
    // Create local copies of the selections to work with in the dialog
    List<String> tempSelectedThemes = List.from(selectedThemes);
    List<String> tempSelectedCountries = List.from(selectedCountries);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.8,
              padding: EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter Stories',
                    style: TextStyle(
                      fontSize: 22, 
                      fontWeight: FontWeight.bold
                    ),
                  ),
                  SizedBox(height: 16),
                  Container(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left column - Theme Tags
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Theme',
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  Spacer(),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (tempSelectedThemes.length == allThemes.length) {
                                          tempSelectedThemes.clear();
                                        } else {
                                          tempSelectedThemes = List.from(allThemes);
                                        }
                                      });
                                    },
                                    child: Text(
                                      tempSelectedThemes.length == allThemes.length ? 'Clear All' : 'Select All'
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: allThemes.map((theme) {
                                      bool isSelected = tempSelectedThemes.contains(theme);
                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            if (isSelected) {
                                              tempSelectedThemes.remove(theme);
                                            } else {
                                              tempSelectedThemes.add(theme);
                                            }
                                          });
                                        },
                                        child: Container(
                                          margin: EdgeInsets.only(bottom: 10),
                                          child: Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 16, 
                                              vertical: 8
                                            ),
                                            decoration: BoxDecoration(
                                              color: isSelected 
                                                  ? ThemeTag.getColor(theme) 
                                                  : Colors.grey.shade200,
                                              borderRadius: BorderRadius.circular(30),
                                            ),
                                            child: Text(
                                              theme,
                                              style: TextStyle(
                                                color: isSelected 
                                                    ? Colors.white 
                                                    : Colors.black87,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 20),
                        // Right column - Country Checkboxes
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Country',
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        if (tempSelectedCountries.length == allCountries.length) {
                                          tempSelectedCountries.clear();
                                        } else {
                                          tempSelectedCountries = List.from(allCountries);
                                        }
                                      });
                                    },
                                    child: Text(
                                      tempSelectedCountries.length == allCountries.length ? 'Clear All' : 'Select All'
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 12),
                              Flexible(
                                child: SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 10.0,
                                    runSpacing: 0.0,
                                    children: allCountries.map((country) {
                                      return SizedBox(
                                        width: MediaQuery.of(context).size.width * 0.2,
                                        child: CheckboxListTile(
                                          contentPadding: EdgeInsets.zero,
                                          dense: true,
                                          title: Text(
                                            country,
                                            style: TextStyle(fontSize: 14),
                                          ),
                                          value: tempSelectedCountries.contains(country),
                                          controlAffinity: ListTileControlAffinity.leading,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              if (value == true) {
                                                tempSelectedCountries.add(country);
                                              } else {
                                                tempSelectedCountries.remove(country);
                                              }
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancel'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Update the main state with the temporary selections
                          this.selectedThemes = tempSelectedThemes;
                          this.selectedCountries = tempSelectedCountries;
                          
                          Navigator.of(context).pop();
                          _loadStories();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            'Apply',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
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
                fontSize: 22, // increased font size for better readability
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.justify, // stretches text nicely across the panel
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