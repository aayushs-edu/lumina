import 'package:flutter/material.dart';
import 'waving_leaf.dart'; // import the waving leaf widget

class SpotlightPanel extends StatelessWidget {
  final String? spotlightTheme;

  const SpotlightPanel({Key? key, this.spotlightTheme}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(maxWidth: 800),
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // The main panel container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color.fromARGB(255, 255, 200, 20).withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 220, 20).withOpacity(0.1),
                    blurRadius: 2,
                    spreadRadius: 0,
                    offset: Offset(0, 0),
                  ),
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 220, 20).withOpacity(0.15),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: Offset(0, 0),
                  ),
                  BoxShadow(
                    color: const Color.fromARGB(255, 255, 220, 20).withOpacity(0.1),
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
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
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
                        shaderCallback: (bounds) => LinearGradient(
                          colors: [
                            Color(0xFFFFD700), // Bright Yellow
                            Color(0xFFFF8C00), // Bright Orange
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ).createShader(bounds),
                        child: Text(
                          spotlightTheme ?? "Loading...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 42,
                            fontWeight: FontWeight.w700,
                            shadows: [
                              Shadow(
                                color: Color(0xFFFFD700).withOpacity(0.8),
                                blurRadius: 15,
                                offset: Offset(0, 0),
                              ),
                              Shadow(
                                color: Color(0xFFFF8C00).withOpacity(0.6),
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
            // Decorative leaf at the top left with a waving effect
            Positioned(
              top: -20,
              left: -20,
              child: WavingLeaf(
                assetPath: 'assets/leaf_top_left_golden.png',
                width: 150,
                initialAngle: 0, // adjust as desired
                amplitude: 0.05,
                duration: Duration(seconds: 2),
              ),
            ),
            // Decorative leaf at the bottom right with a waving effect
            Positioned(
              bottom: -20,
              right: -40,
              child: WavingLeaf(
                assetPath: 'assets/leaf_bottom_right_golden.png',
                width: 250,
                initialAngle: -0.2,
                amplitude: 0.05,
                duration: Duration(seconds: 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}