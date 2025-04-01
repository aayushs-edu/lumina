import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'todays_topic_page.dart';
import 'post_story_page.dart';
import 'create_lumina_post_page.dart';
import 'data_center_page.dart';

void main() {
  runApp(LuminaApp());
}

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
            color: const Color.fromARGB(255, 255, 63, 16),
          ),
          headlineSmall: GoogleFonts.baloo2(
            fontSize: 20,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
          bodyMedium: GoogleFonts.baloo2(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
      ),
      home: HomePage(),
      routes: {
        '/todaysTopic': (context) => TodaysTopicPage(),
        '/postStory': (context) => PostStoryPage(),
        '/createLuminaPost': (context) => CreateLuminaPostPage(),
        '/dataCenter': (context) => DataCenterPage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: AppBar(
          toolbarHeight: 60,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: Colors.white10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo/icon
                  Container(
                    height: 24,
                    width: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white24,
                    ),
                    child: Center(
                      child: Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    ),
                  ),
                  SizedBox(width: 16),
                  // Your navigation items with COSMOS styling
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/todaysTopic');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      "Today's Topic", 
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/postStory');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      "Post a Story", 
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/createLuminaPost');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      "Create a Lumina Post", 
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/dataCenter');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    child: Text(
                      "Data Center", 
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  // Sign In button
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Floating images background effect
          Positioned.fill(
            child: ImagesBackground(),
          ),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main logo/title
                Text(
                  "lumina",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "illuminating hidden inequalities",
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Container(
                      margin: EdgeInsets.only(left: 4),
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.deepOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.deepOrange, width: 1),
                      ),
                      child: Text(
                        "for activists",
                        style: TextStyle(
                          color: Colors.deepOrangeAccent,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                
                SizedBox(height: 200),
                
                // Collection section (similar to "Ethereal Archives" in screenshot)
                Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Today's Stories",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "700 Followers · By",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(width: 4),
                          Text(
                            "@lumina",
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 14,
                            ),
                          ),
                          Icon(
                            Icons.check_circle,
                            color: Colors.deepOrange,
                            size: 14,
                          ),
                        ],
                      ),
                      SizedBox(height: 20),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[800],
                        ),
                        child: Center(
                          child: Icon(Icons.person, color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Bottom navigation
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  // Dark/Light mode toggle
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[900],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: Colors.grey[800],
                          ),
                          child: Text("Dark", style: TextStyle(color: Colors.white)),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text("Light", style: TextStyle(color: Colors.grey)),
                        ),
                      ],
                    ),
                  ),
                  Spacer(),
                  // Scroll to explore button
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[900],
                    ),
                    child: Row(
                      children: [
                        Text("Scroll to explore", style: TextStyle(color: Colors.white70)),
                        SizedBox(width: 8),
                        Icon(Icons.keyboard_arrow_down, color: Colors.white70),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Floating images background effect similar to COSMOS
class ImagesBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: List.generate(20, (index) {
        // Generate random positions for floating image rectangles
        final double top = (index % 5) * 150.0;
        final double left = (index % 7) * 130.0;
        
        return Positioned(
          top: top,
          left: left,
          child: Transform.rotate(
            angle: (index % 10) * 0.1,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey[800]!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        );
      }),
    );
  }
}