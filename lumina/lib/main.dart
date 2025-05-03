import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/connected_map_page.dart';
import 'package:lumina/firebase_options.dart';
import 'package:lumina/lumina_lens_map.dart';
import 'package:lumina/services/firebase_service.dart';
import 'package:lumina/widgets/spotlight_panel.dart';
import 'package:lumina/widgets/waving_leaf.dart';
import 'package:lumina/world_map.dart';
import 'todays_topic_page.dart';
import 'post_story_page.dart';
import 'create_lumina_post_page.dart';
import 'explore_page.dart';
import 'widgets/navbar.dart';
import 'widgets/revolving_stories_dashboard.dart';
import 'widgets/particle_background.dart';
import 'policy_maker_page.dart';
import 'package:lumina/world_map.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
        '/explore': (context) => ExplorePage(),
        '/luminaLens': (context) => LuminaLensPage(),
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
  String? spotlightTheme; // New state for today's spotlight theme

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
    List<Map<String, dynamic>> storiesData =
        await FirebaseService.getAllStories();
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

                      // The existing spotlight panel (unchanged)
                      SpotlightPanel(spotlightTheme: spotlightTheme),

                      SizedBox(height: 40),
                      // Display revolving dashboard only if spotlightTheme is loaded
                      spotlightTheme == null
                          ? CircularProgressIndicator()
                          : RevolvingStoriesDashboard(
                            spotlightTheme: spotlightTheme!,
                          ),
                      SizedBox(height: 40),
                      // New separator between the revolving dashboard and the world map
                      Container(
                        height: 4,
                        width: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Colors.orangeAccent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(height: 40),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(horizontal: 32),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Column(
                              children: [
                                // Inequality Atlas header with red to orange gradient
                                ShaderMask(
                                  shaderCallback:
                                      (bounds) => LinearGradient(
                                        colors: [Colors.red, Colors.orange],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ).createShader(
                                        Rect.fromLTWH(
                                          0,
                                          0,
                                          bounds.width,
                                          bounds.height,
                                        ),
                                      ),
                                  child: Text(
                                    "Inequality Atlas",
                                    style: GoogleFonts.baloo2(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color:
                                          Colors
                                              .white, // This will be masked by the gradient
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 8),
                                // Gray subtitle underneath
                                Text(
                                  "Mapping structural inequalities across the globe",
                                  style: GoogleFonts.baloo2(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                            InteractiveWorldMap(),
                          ],
                        ),
                      ),
                      SizedBox(height: 80),
                      // Add the divider after the world map
                      Container(
                        height: 4,
                        width: MediaQuery.of(context).size.width * 0.8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Colors.orangeAccent,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      SizedBox(
                        height: 60,
                      ), // Increased spacing between sections
                      SizedBox(height: 60),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                        ), // Fixed horizontal padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // "Join the lumina Community" section
                            Container(
                              width: MediaQuery.of(context).size.width / 3,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 40,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            // Use black for the non-gradient parts
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall?.copyWith(
                                              fontSize: 36,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(text: "Join the "),
                                              WidgetSpan(
                                                alignment:
                                                    PlaceholderAlignment
                                                        .baseline,
                                                baseline:
                                                    TextBaseline.alphabetic,
                                                child: ShaderMask(
                                                  shaderCallback:
                                                      (
                                                        bounds,
                                                      ) => LinearGradient(
                                                        colors: [
                                                          Colors.red,
                                                          Colors.orange,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                      ).createShader(
                                                        Rect.fromLTWH(
                                                          0,
                                                          0,
                                                          bounds.width,
                                                          bounds.height,
                                                        ),
                                                      ),
                                                  child: Text(
                                                    "lumina",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineSmall
                                                        ?.copyWith(
                                                          fontSize: 36,
                                                          color:
                                                              Colors
                                                                  .white, // Base color here doesn't matter
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              TextSpan(text: " Community"),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          "Share your experience and help illuminate hidden stories. Your voice matters!",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            fontSize: 24,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        SizedBox(height: 32),
                                        Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.orange,
                                              ],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 24,
                                                vertical: 12,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.pushNamed(
                                                context,
                                                '/postStory',
                                              );
                                            },
                                            child: Text(
                                              "Share Your Story",
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodyMedium?.copyWith(
                                                fontSize: 24,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Overlapping decorative leaf on the bottom right of this panel
                                  Positioned(
                                    bottom: -20,
                                    right: -20,
                                    child: WavingLeaf(
                                      assetPath: 'assets/orange_leaf.png',
                                      width: 100,
                                      initialAngle: 0,
                                      amplitude: 0.05,
                                      duration: Duration(seconds: 3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Spacer between panels
                            SizedBox(width: 40),
                            // "What is lumina?" section
                            Container(
                              width: MediaQuery.of(context).size.width / 3,
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary.withOpacity(0.3),
                                        width: 1,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withOpacity(0.1),
                                          blurRadius: 8,
                                          spreadRadius: 0,
                                          offset: Offset(0, 0),
                                        ),
                                      ],
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 32,
                                      vertical: 40,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        RichText(
                                          textAlign: TextAlign.center,
                                          text: TextSpan(
                                            style: Theme.of(
                                              context,
                                            ).textTheme.headlineSmall?.copyWith(
                                              fontSize: 36,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            children: [
                                              TextSpan(text: "What is "),
                                              WidgetSpan(
                                                alignment:
                                                    PlaceholderAlignment
                                                        .baseline,
                                                baseline:
                                                    TextBaseline.alphabetic,
                                                child: ShaderMask(
                                                  shaderCallback:
                                                      (
                                                        bounds,
                                                      ) => LinearGradient(
                                                        colors: [
                                                          Colors.red,
                                                          Colors.orange,
                                                        ],
                                                        begin:
                                                            Alignment.topLeft,
                                                        end:
                                                            Alignment
                                                                .bottomRight,
                                                      ).createShader(
                                                        Rect.fromLTWH(
                                                          0,
                                                          0,
                                                          bounds.width,
                                                          bounds.height,
                                                        ),
                                                      ),
                                                  child: Text(
                                                    "lumina",
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .headlineSmall
                                                        ?.copyWith(
                                                          fontSize: 36,
                                                          color: Colors.white,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                              TextSpan(text: "?"),
                                            ],
                                          ),
                                        ),
                                        SizedBox(height: 24),
                                        Text(
                                          "Lumina is a platform dedicated to illuminating hidden inequalities and sharing stories of marginalized communities. Our goal is to bring awareness, spark dialogue, and empower individuals to create change. Join us in uncovering untold stories and shaping a more equitable future.",
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium?.copyWith(
                                            fontSize: 24,
                                            color: Colors.black54,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Overlapping decorative leaf on the top left of this panel
                                  Positioned(
                                    top: -20,
                                    left: -20,
                                    child: WavingLeaf(
                                      assetPath:
                                          'assets/leaf_top_left_yellow.png',
                                      width: 100,
                                      initialAngle: 0,
                                      amplitude: 0.05,
                                      duration: Duration(seconds: 3),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 60,
                      ), // Additional spacing before the footer
                      // Footer with copyright
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "lumina © 2025",
                          style: TextStyle(
                            color:
                                Theme.of(context)
                                    .colorScheme
                                    .primary, // Now using primary (orange) color
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
