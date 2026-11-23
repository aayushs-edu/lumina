import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lumina/models/gender_inequality_data.dart';
import 'package:lumina/models/story_model.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/navbar.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:http/http.dart' as http;
import 'package:lumina/naps_data.dart';
import 'package:lumina/widgets/theme_tag.dart';
import 'dart:async';

void main() {
  runApp(const LuminaLensApp());
}

class LuminaLensApp extends StatelessWidget {
  const LuminaLensApp({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumina Lens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFE63946), // Red accent
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: const Color(0xFFF4A261), // Orange accent
          tertiary: const Color(0xFFE9C46A), // Gold-yellow accent
        ),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: GoogleFonts.baloo2().fontFamily,
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontFamily: GoogleFonts.baloo2().fontFamily,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
          displayMedium: TextStyle(
            fontFamily: GoogleFonts.baloo2().fontFamily,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
          bodyLarge: TextStyle(
            fontFamily: GoogleFonts.baloo2().fontFamily,
            color: Colors.black,
          ),
          bodyMedium: TextStyle(
            fontFamily: GoogleFonts.baloo2().fontFamily,
            color: Colors.black,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE63946),
            foregroundColor: Colors.white,
            textStyle: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      home: const LuminaLensPage(),
    );
  }
}

class LuminaLensPage extends StatefulWidget {
  const LuminaLensPage({Key? key}) : super(key: key);

  @override
  State<LuminaLensPage> createState() => _LuminaLensPageState();
}

class _LuminaLensPageState extends State<LuminaLensPage> with TickerProviderStateMixin {
  String selectedCountry = "Norway";
  String selectedRegion = "Europe";
  String selectedCategory = "NAPs";
  bool isGeneratingContent = false;
  bool showAIContent = false;
  String analysisDepth = "Standard";
  int activeTabIndex = 0;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  late TabController _tabController;
  List<Map<String, dynamic>> napsData = [];
  Map<String, dynamic>? selectedCountryData;
  List<Map<String, String>> aiGeneratedContent = [];
  bool isAnimatingContent = false;

  Map<String, List<Map<String, dynamic>>> countryGeneratedNaps = {};

  final List<String> regions = ["Africa", "Americas", "Asia-Pacific", "Europe", "Middle East"];
  final List<String> dataCategories = [
    "NAPs", "Legislation", "Violence Statistics", "Economic Rights", 
    "Political Representation", "Health & Reproductive Rights", "Education"
  ];
  final List<String> analysisDepthOptions = ["Standard", "Detailed", "Comprehensive"];
  final List<String> focusAreas = [
    "Domestic", "Workplace", "Identity", 
    "Healthcare", "Education"
  ];
  
  final Map<String, bool> selectedFocusAreas = {
    "Domestic": true,
    "Workplace": true,
    "Identity": false,
    "Healthcare": false,
    "Education": false,
  };

  List<Story> selectedStories = [];

  final String currentBackendUrl = "https://lumina-backend-x5as.onrender.com/";
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Adjust length based on the number of tabs
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.repeat(reverse: true);
    _loadNapsJson();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNapsJson() async {
    try {
      // Hardcoded data
      napsData = List.from(napsDataJson);
      
      debugPrint("Successfully loaded ${napsData.length} rows from naps.json.");

      // Trigger UI update after loading data
      setState(() {});
    } catch (e, stack) {
      debugPrint("Error loading JSON: $e");
      debugPrint("Stack Trace: $stack");
    }
  }

  void _updateSelectedCountryData(String country) {
    setState(() {
      selectedCountry = country;
      selectedCountryData = napsData.firstWhere(
        (row) => row['Country']?.toString().toLowerCase() == country.toLowerCase(),
        orElse: () => {},
      );
      
      // Make sure numeric values are properly converted to strings
      selectedCountryData?.forEach((key, value) {
        if (value is int || value is double) {
          selectedCountryData![key] = value.toString();
        }
      });
      
      // Check if we have a generated NAP for this country
      if (countryGeneratedNaps.containsKey(selectedCountry)) {
        aiGeneratedContent = countryGeneratedNaps[selectedCountry]!
            .map((e) => e.map((key, value) => MapEntry(key, value.toString())))
            .toList();
        showAIContent = true;
        isAnimatingContent = false; // Don't animate when returning to a country
      } else {
        // Reset AI content only if we don't have a generated NAP for this country
        showAIContent = false;
        aiGeneratedContent = [];
      }
    });
  }

  bool hasNapData() {
    return selectedCountryData != null && 
           selectedCountryData!.containsKey('NAP_Summary') && 
           selectedCountryData!['NAP_Summary'].toString().trim().isNotEmpty;
  }

  // Update the _generateContent method to include a minimum display time
    void _generateContent({required bool isEnhance}) async {
    setState(() {
      isGeneratingContent = true;
      aiGeneratedContent = [];
      showAIContent = false;
      isAnimatingContent = false;
    });

    final selectedFocusAreasList = selectedFocusAreas.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    try {
      // Fetch top 3 stories for the selected country and focus areas
      print("Fetching top stories for country: $selectedCountry and focus areas: $selectedFocusAreasList");
      final results = await FirebaseService.getTopStoriesByCountryAndThemes(
        selectedCountry,
        selectedFocusAreasList,
        3, // Limit to top 3 stories
      );

      if (results.isNotEmpty) {
        final topStories = results.map((map) => Story.fromMap(map)).toList();

        print("Top 3 stories selected:");
        for (final story in topStories) {
          print(story.story);
        }

        setState(() {
          selectedStories = topStories; // Display selected stories
        });
      } else {
        print("No stories found for the selected country and focus areas.");
        setState(() {
          selectedStories = [];
        });
      }

      final payload = {
        "country": selectedCountry,
        "focus_areas": selectedFocusAreasList,
        "stories": selectedStories.map((story) => story.story).toList(),
      };

      final endpoint = isEnhance ? "enhance-policy" : "generate-policy";

      // Create two futures to run in parallel
      final storyDisplayFuture = Future.delayed(Duration(seconds: 5)); // Minimum 5 seconds

      // Make API request in parallel with the timer
      final apiFuture = http.post(
        Uri.parse("$currentBackendUrl/$endpoint"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      // Wait for both to complete - this ensures stories display for at least 5 seconds
      final resultsFuture = await Future.wait([storyDisplayFuture, apiFuture]);
      final response = resultsFuture[1] as http.Response; // Get the API response

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        setState(() {
          aiGeneratedContent = (responseData['output'] as List)
              .map((item) => {
                    "header": item["header"].toString(),
                    "content": item["content"].toString(),
                  })
              .toList();
          isGeneratingContent = false;
          showAIContent = true;
          isAnimatingContent = true;
          selectedStories = []; // Clear the stories now that we have the NAP

          // Add this line to ensure we scroll to the top
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }

          // Update the map of generated NAPs for this country
          countryGeneratedNaps[selectedCountry] = aiGeneratedContent;

          // Recreate the TabController with the new number of tabs (3 instead of 2)
          _tabController.dispose();
          _tabController = TabController(length: 3, vsync: this);
          
          // Jump to the Generated NAP tab (index 2)
          _tabController.animateTo(2);
        });

        // Set a timer to stop animation after all content has been revealed
        final totalAnimationDuration = Duration(
          milliseconds: 2000 * (aiGeneratedContent.length - 1) + 800 + 200,
        );

        Future.delayed(totalAnimationDuration, () {
          if (mounted) {
            setState(() {
              isAnimatingContent = false;
            });
          }
        });
      } else {
        debugPrint("Error: ${response.statusCode} - ${response.body}");
        setState(() {
          isGeneratingContent = false;
          selectedStories = []; // Clear stories on error
        });
        _showErrorDialog("Failed to process the request. Please try again.");
      }
    } catch (e) {
      debugPrint("Error: $e");
      setState(() {
        isGeneratingContent = false;
        selectedStories = []; // Clear stories on error
      });
      _showErrorDialog("An error occurred. Please check your connection and try again.");
    }
  }


  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Selection Panel (Left Side)
                  Flexible(
                    flex: 1,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildCountrySelectionPanel(),
                    ),
                  ),

                  const SizedBox(width: 16), // Spacing between panels

                  // Data Visualization Dashboard (Center)
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildDataVisualizationDashboard(),
                    ),
                  ),

                  const SizedBox(width: 16), // Spacing between panels

                  // AI Policy Maker Panel (Right Side)
                  Flexible(
                    flex: 1, // Allow the panel to take up the remaining space
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 2,
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _buildAIAnalysisPanel(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          const LuminaNavbar(
            currentPage: 'luminaLens',
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFE63946), // Red
                  const Color(0xFFF4A261), // Orange
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.policy, color: Colors.white, size: 32),
                SizedBox(width: 12),
                Text(
                  "LuminaLens Policy Simulator",
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "AI-Powered Policy Analysis",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountrySelectionPanel() {
    // Dynamically fetch the list of countries from the loaded CSV data
    final List<String> countries = napsData.map((row) => row['Country'].toString()).toSet().toList();

    // If the search bar is empty, show all countries
    final List<String> filteredCountries = _searchController.text.isEmpty
        ? countries
        : countries
            .where((country) =>
                country.toLowerCase().contains(_searchController.text.toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with gradient
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFFE63946), // Red
                const Color(0xFFF4A261), // Orange
              ],
            ).createShader(bounds),
            child: Text(
              "Select Country",
              style: TextStyle(
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // Search Bar
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {}); // Trigger UI update when search input changes
            },
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
            ),
            decoration: InputDecoration(
              hintText: "Search countries...",
              prefixIcon: const Icon(Icons.search, color: Color(0xFFE63946)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),

        // Country List
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey.shade50,
            ),
            child: filteredCountries.isEmpty
                ? Center(
                    child: Text(
                      "No countries found",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredCountries.length,
                    itemBuilder: (context, index) {
                      final country = filteredCountries[index];
                      final isSelected = selectedCountry == country;

                      // Check if the country has NAP data
                      final countryData = napsData.firstWhere(
                        (row) => row['Country'] == country,
                        orElse: () => {},
                      );
                      final hasNap = countryData.containsKey('NAP_Summary') &&
                          countryData['NAP_Summary'].toString().trim().isNotEmpty;

                      return InkWell(
                        onTap: () {
                          _updateSelectedCountryData(country);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.grey.shade100 : Colors.transparent,
                            border: isSelected
                                ? Border(
                                    left: BorderSide(
                                      color: const Color(0xFFE63946),
                                      width: 4,
                                    ),
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  country,
                                  style: TextStyle(
                                    fontFamily: GoogleFonts.baloo2().fontFamily,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                              if (hasNap)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE9C46A).withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "NAP",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: const Color(0xFFE9C46A).withAlpha(200),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  // Here's how to modify your _buildDataVisualizationDashboard method to show stories and then NAP
  Widget _buildDataVisualizationDashboard() {
    // If stories are selected and waiting for NAP generation, show story cards with fade-in animation
    if (selectedStories.isNotEmpty && isGeneratingContent) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Add the heading above the stories
          Text(
            "Stories being incorporated into policy generation:",
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFE63946),
            ),
          ),
          const SizedBox(height: 16), // Add spacing below the heading
          Expanded(
            child: AnimatedOpacity(
              opacity: 1.0,
              duration: const Duration(milliseconds: 500),
              child: ListView.builder(
                itemCount: selectedStories.length,
                itemBuilder: (context, index) {
                  final story = selectedStories[index];
                  // Create a fade-in animation for each story card
                  return AnimatedOpacitySlide(
                    delay: Duration(milliseconds: 300 * index), // Staggered delay for each card
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: StoryPanelCard(
                        panel: StoryPanel(
                          title: story.title,
                          content: story.story,
                          country: story.country,
                          likes: story.likes,
                        ),
                        isActive: true, // Make it stand out while processing
                        spotlightTheme: focusAreas.firstWhere(
                          (area) => selectedFocusAreas[area] == true,
                          orElse: () => focusAreas.first,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
    }

    // If NAP content is available to show (either existing or generated)
    if (selectedCountryData != null) {
      // Determine number of tabs - add Generated NAP tab if available
      final int tabCount = aiGeneratedContent.isNotEmpty ? 3 : 2;
      
      // Update TabController if needed
      if (_tabController.length != tabCount) {
        _tabController.dispose();
        _tabController = TabController(length: tabCount, vsync: this);
      }

      return DefaultTabController(
        length: tabCount,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFE63946),
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: const Color(0xFFE63946),
              tabs: [
                Tab(text: "NAP Details"),
                Tab(text: "Legislation"),
                if (aiGeneratedContent.isNotEmpty)
                  Tab(text: "Generated NAP"),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildNapDetailsTab(),
                  _buildLegislationTab(),
                  if (aiGeneratedContent.isNotEmpty)
                    _buildGeneratedNapTab(),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Default fallback for when no data is available
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            "Select a country to view data",
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Add this new method for the Generated NAP tab
  // Update the _buildGeneratedNapTab method to handle different chunk types properly
  Widget _buildGeneratedNapTab() {
    return showAIContent 
        ? (isAnimatingContent 
            ? _buildAnimatedContent() 
            : SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: aiGeneratedContent.map((chunk) {
                    // Get subsections from the chunk
                    final subsections = (chunk['subsections'] as List?) ?? [];
                    final hasContent = (chunk['content'] as String?)?.isNotEmpty ?? false;
                    final isTopLevelTitle = !hasContent && subsections.isEmpty;
                    final hasSubsectionsOnly = !hasContent && subsections.isNotEmpty;
                    
                    // Handle top-level title only
                    if (isTopLevelTitle) {
                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                        child: Text(
                          chunk['header'] ?? '',
                          style: TextStyle(
                            fontFamily: GoogleFonts.baloo2().fontFamily,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 255, 156, 7),
                            letterSpacing: 0.5,
                          ),
                        ),
                      );
                    }
                    
                    // Handle normal panels and subsection-only panels
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section header
                          Text(
                            chunk['header'] ?? '',
                            style: TextStyle(
                              fontFamily: GoogleFonts.baloo2().fontFamily,
                              fontSize: hasSubsectionsOnly ? 24 : 22,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFE63946),
                            ),
                          ),
                          
                          if (hasContent || subsections.isNotEmpty)
                            const SizedBox(height: 16),
                          
                          // Main content
                          if (hasContent)
                            RichText(
                              text: TextSpan(
                                children: _parseTextWithBold(chunk['content'] ?? ''),
                                style: TextStyle(
                                  fontFamily: GoogleFonts.baloo2().fontFamily,
                                  fontSize: 16,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          
                          // Subsections
                          if (subsections.isNotEmpty)
                            ...subsections.map((subsection) => Container(
                              margin: const EdgeInsets.only(top: 16),
                              padding: EdgeInsets.only(
                                left: hasSubsectionsOnly ? 0 : 8,
                                right: 0,
                                top: 8,
                                bottom: 0
                              ),
                              decoration: hasSubsectionsOnly
                                  ? null
                                  : BoxDecoration(
                                      border: Border(
                                        left: BorderSide(
                                          color: const Color(0xFF457B9D).withOpacity(0.3),
                                          width: 3,
                                        ),
                                      ),
                                    ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Subsection title
                                  Text(
                                    subsection['title'] ?? '',
                                    style: TextStyle(
                                      fontFamily: GoogleFonts.baloo2().fontFamily,
                                      fontSize: hasSubsectionsOnly ? 20 : 18,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF457B9D),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Subsection content
                                  RichText(
                                    text: TextSpan(
                                      children: _parseTextWithBold(subsection['content'] ?? ''),
                                      style: TextStyle(
                                        fontFamily: GoogleFonts.baloo2().fontFamily,
                                        fontSize: 16,
                                        height: 1.5,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )).toList(),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ))
        : Center(
            child: Text(
              "Generate a NAP to see content here",
              style: TextStyle(
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          );
  }

  // Helper method to build subsections with proper styling
  List<Widget> _buildSubsections(List subsections) {
    return subsections.map((subsection) {
      final title = subsection['title'] ?? '';
      final content = subsection['content'] ?? '';
      
      return Container(
        margin: const EdgeInsets.only(top: 16, left: 20),
        padding: const EdgeInsets.only(left: 12),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: const Color(0xFF457B9D).withOpacity(0.5),
              width: 2,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subsection title with bullet point
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF457B9D),
                    shape: BoxShape.circle,
                  ),
                ),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF457B9D),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Subsection content
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: RichText(
                text: TextSpan(
                  children: _parseTextWithBold(content),
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildNapDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Key Indicators
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Key Indicators",
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 20,
                    color: const Color(0xFFE63946),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(
                      title: "GII Rank",
                      value: selectedCountryData!['GII_Rank'] ?? "N/A",
                      icon: Icons.leaderboard,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      title: "Violence Against Women",
                      value: "${selectedCountryData!['Proportion of women subjected to physical and/or sexual violence in the last 12 months (% of ever partnered women ages 15-49)'] ?? "N/A"}%",
                      icon: Icons.healing,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildStatCard(
                      title: "Sexual Harassment Laws",
                      value: selectedCountryData!['There is legislation on sexual harassment in employment (1=yes; 0=no)'] == "1" ? "Yes" : "No",
                      icon: Icons.gavel,
                    ),
                    const SizedBox(width: 16),
                    _buildStatCard(
                      title: "Property Rights",
                      value: selectedCountryData!['Women and men have equal ownership rights to immovable property (1=yes; 0=no)'] == "1" ? "Equal" : "Unequal",
                      icon: Icons.home,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // NAP Details sections
          ...[
            "Actors",
            "Timeframe",
            "Objectives",
            "Actions/Activities",
            "Indicators",
            "M&E",
            "Budget",
            "Disarmament",
          ].map((section) {
            final value = selectedCountryData![section];
            if (value == null || value.toString().trim().isEmpty) return SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 24),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section,
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 18,
                      color: const Color(0xFFE63946),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildLegislationTab() {
  final legislation = selectedCountryData!['legislation'];
  if (legislation == null || legislation.toString().trim().isEmpty) {
    return Center(
      child: Text(
        "No legislation data available.",
        style: TextStyle(
          fontFamily: GoogleFonts.baloo2().fontFamily,
          fontSize: 16,
          color: Colors.grey.shade600,
        ),
      ),
    );
  }

  Map<String, dynamic> _parseLegislationTree(String legislation) {
    final Map<String, dynamic> tree = {};
  
    // Split the legislation into individual items
    final items = legislation.split("\n").map((item) => item.trim()).where((item) => item.isNotEmpty);
  
    for (final item in items) {
      // Extract the hierarchy and the title
      final parts = item.split(":");
      if (parts.length < 2) continue;
  
      final hierarchy = parts[0].split(">").map((part) => part.trim()).toList(); // e.g., ["Laws", "Violence against Women"]
      final title = parts[1].trim(); // e.g., "Article 29 of the Constitution"
  
      // Build the nested tree structure
      Map<String, dynamic> currentLevel = tree;
      for (final level in hierarchy) {
        if (!currentLevel.containsKey(level)) {
          currentLevel[level] = <String, dynamic>{}; // Ensure it's a Map<String, dynamic>
        }
        currentLevel = currentLevel[level] as Map<String, dynamic>; // Explicit cast
      }
  
      // Add the title as a leaf node
      if (!currentLevel.containsKey("_items")) {
        currentLevel["_items"] = <String>[]; // Ensure it's a List<String>
      }
      (currentLevel["_items"] as List<String>).add(title); // Explicit cast
    }
  
    return tree;
  }

  // Parse the legislation into a nested tree structure
  final Map<String, dynamic> legislationTree = _parseLegislationTree(legislation.toString());

  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Legislation",
          style: TextStyle(
            fontFamily: GoogleFonts.baloo2().fontFamily,
            fontSize: 22,
            color: const Color(0xFFE63946),
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Display the legislation tree
        _buildTree(legislationTree),
      ],
    ),
  );
}

  Widget _buildStatCard({required String title, required String value, required IconData icon}) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Color(0xFFE63946).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Color(0xFFE63946),
                size: 20,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
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

  // Enhanced text reveal animation for NAP content
  Widget _buildAnimatedContent() {
    return SequentialSectionAnimator(
      content: aiGeneratedContent,
      scrollController: _scrollController,
      onAllComplete: () {
        // Stop animation state when all sections complete
        if (mounted) {
          setState(() {
            isAnimatingContent = false;
          });
        }
      },
    );
  }

  Widget _buildAIAnalysisPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title with gradient
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              const Color(0xFFE63946), // Red
              const Color(0xFFF4A261), // Orange
            ],
          ).createShader(bounds),
          child: Text(
            "AI Policy Maker",
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              fontSize: 28, // Increased font size
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 16), // Increased spacing

        // Action description
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16), // Increased padding
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                hasNapData() ? "Enhance NAP" : "Generate NAP",
                style: TextStyle(
                  fontFamily: GoogleFonts.baloo2().fontFamily,
                  fontSize: 20, // Increased font size
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFE63946),
                ),
              ),
              const SizedBox(height: 8), // Increased spacing
              Text(
                hasNapData()
                    ? "Improve existing policy"
                    : "Create new framework",
                style: TextStyle(
                  fontFamily: GoogleFonts.baloo2().fontFamily,
                  fontSize: 16, // Increased font size
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16), // Increased spacing

        // Focus areas
        Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16), // Increased padding
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Focus Areas",
                style: TextStyle(
                  fontFamily: GoogleFonts.baloo2().fontFamily,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Increased font size
                ),
              ),
              const SizedBox(height: 12), // Increased spacing
              Wrap(
                spacing: 8, // Increased spacing
                runSpacing: 8, // Increased spacing
                children: focusAreas.map((area) {
                  final isSelected = selectedFocusAreas[area] ?? false;
                  return FilterChip(
                    label: Text(
                      area,
                      style: const TextStyle(fontSize: 14), // Increased font size
                    ),
                    selected: isSelected,
                    checkmarkColor: const Color(0xFFE63946),
                    selectedColor: const Color(0xFFE63946).withOpacity(0.1),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? const Color(0xFFE63946)
                          : Colors.grey.shade800,
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        selectedFocusAreas[area] = selected;
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),

        // Generate button
        Container(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isGeneratingContent
                ? null
                : () => _generateContent(isEnhance: hasNapData()), // Pass true for "Improve NAP", false for "Generate Policy"
            icon: isGeneratingContent
                ? const SizedBox(
                    width: 20, // Increased size
                    height: 20, // Increased size
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Icon(
                    hasNapData()
                        ? Icons.auto_awesome // Icon for "Improve NAP"
                        : Icons.add_circle_outline, // Icon for "Generate Policy"
                    size: 20, // Increased size
                    color: Colors.white,
                  ),
            label: Text(
              isGeneratingContent
                  ? "Processing..."
                  : hasNapData()
                      ? "Improve NAP" // Label for "Improve NAP"
                      : "Generate Policy", // Label for "Generate Policy"
              style: const TextStyle(fontSize: 16, color: Colors.white), // Increased font size
            ),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16), // Increased padding
              backgroundColor: const Color(0xFFE63946),
              disabledBackgroundColor: const Color(0xFFE63946).withOpacity(0.5),
            ),
          ),
        ),

        const SizedBox(height: 16), // Increased spacing

        // AI Capabilities
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16), // Increased padding
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListView(
              children: [
                Text(
                  "AI Capabilities",
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 18, // Increased font size
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE63946),
                  ),
                ),
                const SizedBox(height: 12), // Increased spacing
                _buildCapabilityItem(
                  icon: Icons.psychology,
                  title: "Policy Analysis",
                ),
                _buildCapabilityItem(
                  icon: Icons.compress,
                  title: "Comparative Analysis",
                ),
                _buildCapabilityItem(
                  icon: Icons.timeline,
                  title: "Implementation Planning",
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCapabilityItem({
    required IconData icon,
    required String title,
    String? description,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8), // Reduced margin
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(6), // Reduced padding
            decoration: BoxDecoration(
              color: const Color(0xFFE63946).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6), // Smaller radius
            ),
            child: Icon(
              icon,
              size: 12, // Smaller icon
              color: const Color(0xFFE63946),
            ),
          ),
          SizedBox(width: 8), // Reduced spacing
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontWeight: FontWeight.w500,
                fontSize: 12, // Smaller text
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: Colors.grey.shade50,
      child: Row(
        children: [
          Text(
            "© 2025 Lumina",
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              color: Colors.grey.shade600,
              fontSize: 14,
            ),
          ),
          Spacer(),
          Text(
            "Powered by LuminaLens AI",
            style: TextStyle(
              fontFamily: GoogleFonts.baloo2().fontFamily,
              color: const Color(0xFFE63946),
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// Update the AnimatedOpacitySlide widget for smoother animations
class AnimatedOpacitySlide extends StatefulWidget {
  final Widget child;
  final Duration delay;
  
  const AnimatedOpacitySlide({
    Key? key,
    required this.child,
    required this.delay,
  }) : super(key: key);

  @override
  State<AnimatedOpacitySlide> createState() => _AnimatedOpacitySlideState();
}

class _AnimatedOpacitySlideState extends State<AnimatedOpacitySlide> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _opacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(0.0, 0.75, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.2), // Subtle slide from below
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );
    
    // Apply delay before starting animation
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.forward();
      }
    });
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: widget.child,
      ),
    );
  }
}

List<InlineSpan> _parseTextWithBold(String text) {
  final List<InlineSpan> spans = [];
  final RegExp boldPattern = RegExp(r'\*\*(.*?)\*\*');
  
  int currentPosition = 0;
  
  for (final match in boldPattern.allMatches(text)) {
    // Add text before the match
    if (match.start > currentPosition) {
      spans.add(
        TextSpan(
          text: text.substring(currentPosition, match.start),
        ),
      );
    }
    
    // Add the bold text (without the ** markers)
    spans.add(
      TextSpan(
        text: match.group(1),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
    
    currentPosition = match.end;
  }
  
  // Add remaining text
  if (currentPosition < text.length) {
    spans.add(
      TextSpan(
        text: text.substring(currentPosition),
      ),
    );
  }
  
  return spans;
}

Widget _buildTree(Map<String, dynamic> tree) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: tree.entries.map((entry) {
      if (entry.key == "_items") {
        // Leaf nodes (list of items)
        return Column(
          children: (entry.value as List<dynamic>).map((item) {
            return ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: Icon(Icons.arrow_right, color: const Color(0xFFE63946)),
              title: Text(
                item.toString(), // Convert each item to a string
                style: TextStyle(
                  fontFamily: GoogleFonts.baloo2().fontFamily,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            );
          }).toList(),
        );
      } else {
        // Parent nodes (nested ExpansionTile)
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ExpansionTile(
            title: Text(
              entry.key,
              style: TextStyle(
                fontFamily: GoogleFonts.baloo2().fontFamily,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFE63946),
              ),
            ),
            children: [_buildTree(Map<String, dynamic>.from(entry.value as Map))], // Explicit cast
          ),
        );
      }
    }).toList(),
  );
}

Map<String, dynamic> _parseLegislationTree(String legislation) {
  final Map<String, dynamic> tree = {};

  // Split the legislation into individual items
  final items = legislation.split("\n").map((item) => item.trim()).where((item) => item.isNotEmpty);

  for (final item in items) {
    // Extract the hierarchy and the title
    final parts = item.split(":");
    if (parts.length < 2) continue;

    final hierarchy = parts[0].split(">").map((part) => part.trim()).toList(); // e.g., ["Laws", "Violence against Women"]
    final title = parts[1].trim(); // e.g., "Article 29 of the Constitution"

    // Build the nested tree structure
    Map<String, dynamic> currentLevel = tree;
    for (final level in hierarchy) {
      if (!currentLevel.containsKey(level)) {
        currentLevel[level] = <String, dynamic>{}; // Ensure it's a Map<String, dynamic>
      }
      currentLevel = currentLevel[level] as Map<String, dynamic>; // Explicit cast
    }

    // Add the title as a leaf node
    if (!currentLevel.containsKey("_items")) {
      currentLevel["_items"] = <String>[]; // Ensure it's a List<String>
    }
    (currentLevel["_items"] as List<String>).add(title); // Explicit cast
  }

  return tree;
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
        constraints: BoxConstraints(
          maxWidth: 200,
          minHeight: 100,
        ),
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
                              fontSize: 22,
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
                        fontSize: 18,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2, // increased from 1 to 4 for a longer preview
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 20),
                    // Bottom row: likes at left, country at right
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${panel.likes}',
                              style: GoogleFonts.baloo2(
                                fontSize: 16,
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
                            fontSize: 16,
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

class AnimatedTypingText extends StatefulWidget {
  final String text;
  final TextStyle style;
  final Duration typingSpeed;
  final VoidCallback? onCompleted;
  final bool animate;
  final Color cursorColor;

  const AnimatedTypingText({
    Key? key,
    required this.text,
    required this.style,
    this.typingSpeed = const Duration(milliseconds: 10),
    this.onCompleted,
    this.animate = true,
    this.cursorColor = const Color(0xFF457B9D),
  }) : super(key: key);

  @override
  _AnimatedTypingTextState createState() => _AnimatedTypingTextState();
}

class _AnimatedTypingTextState extends State<AnimatedTypingText> with SingleTickerProviderStateMixin {
  String _displayText = "";
  int _charIndex = 0;
  Timer? _timer;
  bool _isComplete = false;
  late AnimationController _cursorController;
  late Animation<double> _cursorOpacity;

  @override
  void initState() {
    super.initState();

    // Setup cursor blink animation
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _cursorOpacity = Tween<double>(begin: 0.0, end: 1.0).animate(_cursorController);
    _cursorController.repeat(reverse: true);

    if (widget.animate) {
      _startAnimation();
    } else {
      _displayText = widget.text;
      _isComplete = true;
    }
  }

  @override
  void didUpdateWidget(AnimatedTypingText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.text != oldWidget.text || widget.animate != oldWidget.animate) {
      _charIndex = 0;
      _displayText = "";
      _isComplete = false;
      if (widget.animate) {
        _startAnimation();
      } else {
        setState(() {
          _displayText = widget.text;
          _isComplete = true;
        });
      }
    }
  }

  void _startAnimation() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.typingSpeed, (timer) {
      if (_charIndex < widget.text.length) {
        setState(() {
          _displayText = widget.text.substring(0, _charIndex + 1);
          _charIndex++;
        });
      } else {
        timer.cancel();
        setState(() {
          _isComplete = true;
        });
        widget.onCompleted?.call();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cursorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _displayText,
            style: widget.style,
          ),
        ),
        if (widget.animate && !_isComplete)
          FadeTransition(
            opacity: _cursorOpacity,
            child: Container(
              height: widget.style.fontSize! * 1.2,
              width: 2.5,
              margin: const EdgeInsets.only(left: 1, bottom: 3),
              decoration: BoxDecoration(
                color: widget.cursorColor,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
      ],
    );
  }
}

class AnimatedSection extends StatefulWidget {
  final Map<String, dynamic> chunk;
  final Duration initialDelay;
  final VoidCallback? onAnimationComplete;
  final bool startAnimation;

  const AnimatedSection({
    Key? key,
    required this.chunk,
    required this.initialDelay,
    this.onAnimationComplete,
    this.startAnimation = false,
  }) : super(key: key);

  @override
  _AnimatedSectionState createState() => _AnimatedSectionState();
}

class _AnimatedSectionState extends State<AnimatedSection> with SingleTickerProviderStateMixin {
  late AnimationController _appearController;
  late Animation<double> _opacityAnimation;
  late Animation<Offset> _slideAnimation;

  bool _showHeader = false;
  bool _showMainContent = false;
  List<int> _visibleSubsections = [];
  bool _animationCompleted = false;

  @override
  void initState() {
    super.initState();

    // Setup appearance animation
    _appearController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _appearController, curve: Curves.easeOutCubic),
    );

    // Start animation if startAnimation is true
    if (widget.startAnimation) {
      _beginAnimation();
    }
  }

  @override
  void didUpdateWidget(AnimatedSection oldWidget) {
    super.didUpdateWidget(oldWidget);

    // If startAnimation changes from false to true, begin the animation
    if (widget.startAnimation && !oldWidget.startAnimation) {
      _beginAnimation();
    }
  }

  void _beginAnimation() {
    // Start delayed sequence
    Future.delayed(widget.initialDelay, () {
      if (mounted) {
        _appearController.forward();
        _startTypingSequence();
      }
    });
  }

  void _startTypingSequence() {
    // Step 1: Show header
    setState(() {
      _showHeader = true;
    });

    // Step 2: Show main content after header is typed
    Future.delayed(Duration(milliseconds: (300 + (widget.chunk['header']?.length ?? 0) * 10).toInt()), () {
      if (mounted) {
        setState(() {
          _showMainContent = true;
        });

        // Step 3: Show subsections one by one
        _animateSubsections();
      }
    });
  }

  void _animateSubsections() {
    // Safely handle null or non-list subsections
    final subsections = (widget.chunk['subsections'] as List?) ?? [];
    if (subsections.isEmpty) {
      _completeAnimation();
      return;
    }

    for (int i = 0; i < subsections.length; i++) {
      Future.delayed(Duration(milliseconds: i * 500), () {
        if (mounted) {
          setState(() {
            _visibleSubsections.add(i);
          });

          // Check if this was the last subsection
          if (i == subsections.length - 1) {
            _completeAnimation();
          }
        }
      });
    }
  }

  void _completeAnimation() {
    if (mounted && !_animationCompleted) {
      setState(() {
        _animationCompleted = true;
      });
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void dispose() {
    _appearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final subsections = (widget.chunk['subsections'] as List?) ?? [];
    final hasContent = (widget.chunk['content'] as String?)?.isNotEmpty ?? false;
    final isTopLevelTitle = !hasContent && subsections.isEmpty;
    final hasSubsectionsOnly = !hasContent && subsections.isNotEmpty;
    
    // If this is a top-level title only (no content, no subsections)
    if (isTopLevelTitle) {
      return FadeTransition(
        opacity: _opacityAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: _showHeader
                ? AnimatedTypingText(
                    text: widget.chunk['header'] ?? '',
                    style: TextStyle(
                      fontFamily: GoogleFonts.baloo2().fontFamily,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 255, 177, 7),
                      letterSpacing: 0.5,
                    ),
                    typingSpeed: const Duration(milliseconds: 15),
                    onCompleted: _completeAnimation,
                  )
                : const SizedBox.shrink(),
          ),
        ),
      );
    }
    
    // For regular sections and subsection-only sections
    return FadeTransition(
      opacity: _opacityAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          margin: const EdgeInsets.only(bottom: 24),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header
              _showHeader
                  ? AnimatedTypingText(
                      text: widget.chunk['header'] ?? '',
                      style: TextStyle(
                        fontFamily: GoogleFonts.baloo2().fontFamily,
                        fontSize: hasSubsectionsOnly ? 24 : 22,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFE63946),
                      ),
                      typingSpeed: const Duration(milliseconds: 10),
                    )
                  : const SizedBox.shrink(),
                  
              if (hasContent || subsections.isNotEmpty)
                const SizedBox(height: 16),
              
              // Main content
              if (_showMainContent && hasContent)
                AnimatedTypingText(
                  text: widget.chunk['content'] ?? '',
                  style: TextStyle(
                    fontFamily: GoogleFonts.baloo2().fontFamily,
                    fontSize: 16,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                  typingSpeed: const Duration(milliseconds: 2),
                ),
              
              // Subsections
              if (subsections.isNotEmpty)
                ...List.generate(subsections.length, (index) {
                  if (!_visibleSubsections.contains(index)) {
                    return const SizedBox.shrink();
                  }
                  
                  final subsection = subsections[index];
                  return Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: EdgeInsets.only(
                      left: hasSubsectionsOnly ? 0 : 8,
                      right: 0,
                      top: 8,
                      bottom: 0
                    ),
                    decoration: hasSubsectionsOnly
                        ? null
                        : BoxDecoration(
                            border: Border(
                              left: BorderSide(
                                color: const Color(0xFF457B9D).withOpacity(0.3),
                                width: 3,
                              ),
                            ),
                          ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subsection title
                        AnimatedTypingText(
                          text: subsection['title'] ?? '',
                          style: TextStyle(
                            fontFamily: GoogleFonts.baloo2().fontFamily,
                            fontSize: hasSubsectionsOnly ? 20 : 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF457B9D),
                          ),
                          typingSpeed: const Duration(milliseconds: 10),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Subsection content
                        AnimatedTypingText(
                          text: subsection['content'] ?? '',
                          style: TextStyle(
                            fontFamily: GoogleFonts.baloo2().fontFamily,
                            fontSize: 16,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          typingSpeed: const Duration(milliseconds: 3),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

class SequentialSectionAnimator extends StatefulWidget {
  final List<Map<String, dynamic>> content;
  final ScrollController scrollController;
  final VoidCallback onAllComplete;

  const SequentialSectionAnimator({
    Key? key,
    required this.content,
    required this.scrollController,
    required this.onAllComplete,
  }) : super(key: key);

  @override
  _SequentialSectionAnimatorState createState() => _SequentialSectionAnimatorState();
}

class _SequentialSectionAnimatorState extends State<SequentialSectionAnimator> {
  List<bool> _sectionsToAnimate = [];

  @override
  void initState() {
    super.initState();

    // Initialize with only the first section set to animate
    _sectionsToAnimate = List.generate(widget.content.length, (index) => index == 0);
  }

  void _onSectionComplete(int index) {
    // When a section completes, start the next one
    if (index < widget.content.length - 1) {
      // Short delay before starting the next section
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _sectionsToAnimate[index + 1] = true;
          });

          // Auto-scroll to make the next section visible
          Future.delayed(const Duration(milliseconds: 100), () {
            if (widget.scrollController.hasClients) {
              final double offset = (index + 1) * 150.0; // Rough estimate
              widget.scrollController.animateTo(
                offset,
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOut,
              );
            }
          });
        }
      });
    } else {
      // This was the last section
      widget.onAllComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          widget.content.length,
          (index) {
            final isLastSection = index == widget.content.length - 1;

            return AnimatedSection(
              chunk: widget.content[index],
              initialDelay: const Duration(milliseconds: 100),
              startAnimation: _sectionsToAnimate[index],
              onAnimationComplete: () {
                _onSectionComplete(index);
              },
            );
          },
        ),
      ),
    );
  }
}