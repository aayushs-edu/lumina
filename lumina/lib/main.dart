import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lumina/connected_map_page.dart';
import 'package:lumina/firebase_options.dart';
import 'package:lumina/lumina_lens_map.dart';
import 'package:lumina/models/story_themes.dart';
import 'package:lumina/widgets/home_sections.dart';
import 'package:lumina/world_map.dart';
import 'todays_topic_page.dart';
import 'post_story_page.dart';
import 'create_lumina_post_page.dart';
import 'explore_page.dart';
import 'widgets/navbar.dart';
import 'widgets/hero/lumina_hero.dart';
import 'policy_maker_page.dart';

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
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Today's spotlight theme, from the fixed theme list.
  final String spotlightTheme = spotlightThemeFor(DateTime.now());
  final GlobalKey _spotlightKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePalette.paper,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'home'),
      ),
      // Tab order follows the page's reading order (spotlight, stories,
      // then the closing invitation) rather than on-screen geometry.
      body: FocusTraversalGroup(
        policy: WidgetOrderTraversalPolicy(),
        child: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Repaint boundaries keep each animated section from
                      // repainting the rest of the page (notably the world map).
                      RepaintBoundary(
                        child: LuminaHero(
                          onScrollCue: () {
                            final ctx = _spotlightKey.currentContext;
                            if (ctx != null) {
                              Scrollable.ensureVisible(
                                ctx,
                                duration: const Duration(milliseconds: 700),
                                curve: Curves.easeInOutCubic,
                                alignment: 0.1,
                              );
                            }
                          },
                        ),
                      ),
                      KeyedSubtree(
                        key: _spotlightKey,
                        child: SpotlightStoriesSection(theme: spotlightTheme),
                      ),
                      const _AtlasSection(),
                      const HomeClosingSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }
}

/// The Inequality Atlas on a warm-white ground, framed square.
class _AtlasSection extends StatelessWidget {
  const _AtlasSection();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final gutter = homeGutter(width);
        final wide = width >= 900;
        return Container(
          width: double.infinity,
          color: HomePalette.paper,
          padding: EdgeInsets.fromLTRB(
            gutter,
            wide ? 112 : 64,
            gutter,
            wide ? 112 : 64,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: RepaintBoundary(
                child: InteractiveWorldMap(
                  header: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inequality Atlas',
                        style: GoogleFonts.baloo2(
                          fontSize: wide ? 48 : 36,
                          fontWeight: FontWeight.w700,
                          height: 1.05,
                          letterSpacing: -1,
                          color: HomePalette.ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mapping structural inequalities across the globe',
                        style: GoogleFonts.baloo2(
                          fontSize: wide ? 20 : 18,
                          color: HomePalette.soft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
