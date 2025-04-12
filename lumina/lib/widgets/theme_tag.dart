import 'package:flutter/material.dart';

class ThemeTag extends StatelessWidget {
  final String theme;
  final String? currentSpotlight; // Pass the current spotlight theme

  const ThemeTag({
    Key? key,
    required this.theme,
    this.currentSpotlight,
  }) : super(key: key);

  // Helper function to decide if this tag is the spotlight theme.
  bool get isSpotlight => currentSpotlight != null && currentSpotlight == theme;

  // Static helper to get the mapped color for a theme.
  static Color getColor(String theme) {
    switch (theme) {
      case 'Workplace':
        return Colors.pinkAccent;
      case 'Domestic':
        return Colors.purpleAccent;
      case 'Educational':
        return Colors.deepPurpleAccent;
      case 'Healthcare':
        return Colors.pink;
      case 'Public Space':
        return Colors.pink.shade200;
      default:
        return Colors.pink.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        // If this tag is spotlight, use the special gradient decoration; otherwise use the mapped color.
        gradient: isSpotlight
            ? LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
        color: isSpotlight ? null : getColor(theme),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        theme,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
