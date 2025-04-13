import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/firebase_options.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/world_map.dart';
import 'todays_topic_page.dart';
import 'post_story_page.dart';
import 'create_lumina_post_page.dart';
import 'data_center_page.dart';
import 'explore_page.dart';
import 'widgets/navbar.dart';
import 'widgets/revolving_stories_dashboard.dart';
import 'widgets/particle_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(LuminaApp());
}

// Rest of your main.dart file remains the same

class LuminaApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.light(
          primary: const Color.fromARGB(255, 255, 102, 0),
          secondary: Colors.black,
        ),
        scaffoldBackgroundColor: Colors.black,
        textTheme: TextTheme(
          headlineLarge: GoogleFonts.baloo2(
            fontSize: 100,
            fontWeight: FontWeight.w700,
            color: const Color.fromARGB(255, 255, 255, 255),
          ),
          headlineSmall: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          bodyMedium: GoogleFonts.baloo2(fontSize: 16, color: Colors.black),
        ),
      ),
      home: HomePage(),
      routes: {
        '/todaysTopic': (context) => TodaysTopicPage(),
        '/postStory': (context) => PostStoryPage(),
        '/dataCenter': (context) => DataCenterPage(),
        '/explore': (context) => ExplorePage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  final GlobalKey luminaTextKey = GlobalKey();

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _gradientController;
  String? spotlightTheme;  // New state for today's spotlight theme
  
  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _loadSpotlightTheme();
  }
  
  Future<void> _loadSpotlightTheme() async {
    // Get all stories and extract unique themes
    List<Map<String, dynamic>> storiesData = await FirebaseService.getAllStories();
    Set<String> themesSet = {};
    for (var story in storiesData) {
      if (story.containsKey('themes')) {
        for (var t in story['themes']) {
          themesSet.add(t.toString());
        }
      }
    }
    List<String> themes = themesSet.toList();
    print(themes); // Debugging line to check themes
    if (themes.isNotEmpty) {
      // Rotate through themes by day (using day-of-month as index)
      int index = DateTime.now().day % themes.length;
      setState(() {
        spotlightTheme = themes[index];
      });
    }
  }
  
  @override
  void dispose() {
    _gradientController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'home'),
      ),
      body: Stack(
        children: [
          ParticleBackground(luminaTextKey: widget.luminaTextKey),
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Initial space to center the text vertically
                      SizedBox(height: MediaQuery.of(context).size.height / 3),
                      // Lumina text
                      Center(
                        child: AnimatedBuilder(
                          animation: _gradientController,
                          builder: (context, child) {
                            final progress = _gradientController.value;
                            final gradient = LinearGradient(
                              colors: [
                                const Color.fromARGB(238, 255, 136, 0),
                                const Color.fromARGB(255, 255, 20, 20),
                                const Color.fromARGB(238, 255, 136, 0),
                              ],
                              stops:
                                  [progress - 0.5, progress, progress + 0.5]
                                      .map((stop) => stop.clamp(0.0, 1.0))
                                      .toList(),
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            );
                            return ShaderMask(
                              shaderCallback:
                                  (bounds) => gradient.createShader(bounds),
                              child: Text(
                                "lumina",
                                key: widget.luminaTextKey,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineLarge?.copyWith(
                                  // Remove glow by omitting or setting shadows to empty
                                  shadows: [],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      // Subtitle
                      Center(
                        child: Text(
                          "illuminating hidden inequalities",
                          style: Theme.of(
                            context,
                          ).textTheme.headlineSmall?.copyWith(
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      SizedBox(height: 100),
                      // Theme panel
                      Center(
                        child: Container(
                          constraints: BoxConstraints(maxWidth: 800),
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color.fromARGB(
                                  255,
                                  255,
                                  20,
                                  20,
                                ).withOpacity(0.3),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    20,
                                    20,
                                  ).withOpacity(0.1),
                                  blurRadius: 2,
                                  spreadRadius: 0,
                                  offset: Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    20,
                                    20,
                                  ).withOpacity(0.15),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                  offset: Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: const Color.fromARGB(
                                    255,
                                    255,
                                    20,
                                    20,
                                  ).withOpacity(0.1),
                                  blurRadius: 20,
                                  spreadRadius: 0,
                                  offset: Offset(0, 0),
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            padding: EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 24,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "Today's Spotlight",
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 16),
                                Stack(
                                  children: [
                                    ShaderMask(
                                      shaderCallback:
                                          (bounds) => LinearGradient(
                                            colors: [
                                              Color(0xFFFFD700), // Bright Yellow
                                              Color(0xFFFF8C00), // Bright Orange
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          ).createShader(bounds),
                                      child: Text(
                                        spotlightTheme ?? "Loading...", // Changed from "Gender Inequality"
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 42,
                                          fontWeight: FontWeight.w700,
                                          shadows: [
                                            Shadow(
                                              color: Color(0xFFFFD700).withOpacity(0.8), // Yellow shadow
                                              blurRadius: 15,
                                              offset: Offset(0, 0),
                                            ),
                                            Shadow(
                                              color: Color(0xFFFF8C00).withOpacity(0.6), // Orange shadow
                                              blurRadius: 30,
                                              offset: Offset(0, 0),
                                            ),
                                          ],
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 24),
                                // The button is wrapped in an Align so it doesn't affect the panel's width.
                                Align(
                                  alignment: Alignment.center,
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 4,
                                    ),
                                    onPressed: () {
                                      if (spotlightTheme != null) {
                                        Navigator.pushNamed(
                                          context,
                                          '/explore',
                                          arguments: {'applySpotlightFilter': true},
                                        );
                                      }
                                    },
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Transform.rotate(
                                          angle: -0.3,
                                          child: Icon(
                                            Icons.arrow_forward,
                                            size: 24,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          "View Stories",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 40),
                      // Display revolving dashboard only if spotlightTheme is loaded
                      spotlightTheme == null
                          ? CircularProgressIndicator()
                          : RevolvingStoriesDashboard(spotlightTheme: spotlightTheme!),
                      SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [InteractiveWorldMap()],
                        ),
                      ),
                      SizedBox(height: 60), // Increased spacing between sections
                      Center(
                        child: ConstrainedBox(
                          // New width: one-third of screen width
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 3),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  textAlign: TextAlign.center,
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontSize: 36, // Increased header font size
                                      color: Theme.of(context).colorScheme.primary, // header text is orange
                                      fontWeight: FontWeight.bold,
                                    ),
                                    children: [
                                      TextSpan(text: "Join the "),
                                      TextSpan(
                                        text: "lumina",
                                        style: TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      TextSpan(text: " Community"),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "Share your experience and help illuminate hidden stories. Your voice matters!",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 24, // Increased body font size
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 32),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.primary,
                                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    elevation: 4,
                                  ),
                                  onPressed: () {
                                    Navigator.pushNamed(context, '/postStory');
                                  },
                                  child: Text(
                                    "Share Your Story",
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontSize: 24, // Increased button text font size
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 60), // Increased spacing between sections
                      Center(
                        child: ConstrainedBox(
                          // Constrain to one-third of screen width
                          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width / 3),
                          child: Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  "What is lumina?",
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontSize: 36, // Increased header font size
                                    color: Theme.of(context).colorScheme.primary, // header text is orange
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 24),
                                Text(
                                  "Lumina is a platform dedicated to illuminating hidden inequalities and sharing stories of marginalized communities. Our goal is to bring awareness, spark dialogue, and empower individuals to create change. Join us in uncovering untold stories and shaping a more equitable future.",
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 24, // Increased body font size
                                    color: Colors.black54,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 60), // Additional spacing before the footer
                      // Footer with copyright
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "lumina © 2025",
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary, // Now using primary (orange) color
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
