import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Add this import

class LuminaNavbar extends StatelessWidget {
  final String currentPage;

  const LuminaNavbar({Key? key, this.currentPage = ''}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PreferredSize(
      preferredSize: Size.fromHeight(60),
      child: AppBar(
        toolbarHeight: 60,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 100, // Increase the width allocated for the leading widget
        leading: Padding(
          padding: EdgeInsets.only(left: 16),
          child: TextButton(
            onPressed: () {
              if (currentPage != 'home') {
                Navigator.pushReplacementNamed(context, '/');
              }
            },
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 4),
              alignment: Alignment.center, // Changed from centerLeft to center
              minimumSize: Size(80, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              // Remove hover highlight
              overlayColor: Colors.transparent,
            ),
            child: Text(
              "lumina",
              style: GoogleFonts.baloo2(
                color: const Color.fromARGB(255, 255, 102, 0),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center, // Ensure text is center-aligned
            ),
          ),
        ),
        title: Center(
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Explore with icon
                Row(
                  children: [
                    Icon(
                      Icons.auto_awesome,
                      size: 16,
                      color: currentPage == 'explore' 
                          ? const Color.fromARGB(255, 255, 102, 0)
                          : Colors.black54,
                    ),
                    SizedBox(width: 4),
                    TextButton(
                      onPressed: () {
                        if (currentPage != 'explore') {
                          Navigator.pushReplacementNamed(context, '/explore');
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      ),
                      child: Text(
                        "Explore",
                        style: TextStyle(
                          color: currentPage == 'explore' 
                              ? const Color.fromARGB(255, 255, 102, 0)
                              : Colors.black,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 16),
                // Today's Spotlight
                TextButton(
                  onPressed: () {
                    if (currentPage != 'todaysTopic') {
                      Navigator.pushReplacementNamed(context, '/todaysTopic');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    "Today's Spotlight",
                    style: TextStyle(
                      color: currentPage == 'todaysTopic' 
                          ? const Color.fromARGB(255, 255, 102, 0)
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Post a Story
                TextButton(
                  onPressed: () {
                    if (currentPage != 'postStory') {
                      Navigator.pushReplacementNamed(context, '/postStory');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    "Post a Story",
                    style: TextStyle(
                      color: currentPage == 'postStory' 
                          ? const Color.fromARGB(255, 255, 102, 0)
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                // Data Center
                TextButton(
                  onPressed: () {
                    if (currentPage != 'dataCenter') {
                      Navigator.pushReplacementNamed(context, '/dataCenter');
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: Text(
                    "Data Center",
                    style: TextStyle(
                      color: currentPage == 'dataCenter' 
                          ? const Color.fromARGB(255, 255, 102, 0)
                          : Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}