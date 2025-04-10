import 'package:flutter/material.dart';

class ThemeTag extends StatelessWidget {
  final String theme;
  const ThemeTag({required this.theme});

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
    final color = ThemeTag.getColor(theme);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        theme,
        style: TextStyle(color: Colors.white, fontSize: 14),
      ),
    );
  }
}
