import 'package:flutter/material.dart';
import '../../widgets/theme_tag.dart';

class HotspotPopup extends StatelessWidget {
  final String countryName;
  final String severity;
  final int storyCount;
  final List<String> themes;

  const HotspotPopup({
    Key? key,
    required this.countryName,
    required this.severity,
    required this.storyCount,
    required this.themes,
  }) : super(key: key);

  Color _getSeverityColor() {
    switch (severity) {
      case 'High':
        return const Color.fromARGB(255, 255, 20, 20);
      case 'Medium':
        return const Color.fromARGB(255, 255, 102, 0);
      case 'Low':
        return const Color.fromARGB(255, 200, 200, 0);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severityColor = _getSeverityColor();
    return Material(
      elevation: 4.0,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: 200),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inequality Hotspot',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: severityColor,
                fontSize: 18, // increased font size
              ),
            ),
            SizedBox(height: 4),
            Text(
              countryName,
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w500,
                fontSize: 16, // increased font size
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Stories: $storyCount',
              style: TextStyle(
                color: Colors.black87,
                fontSize: 16, // increased font size
              ),
            ),
            SizedBox(height: 4),
            Wrap(
              spacing: 4,
              children: themes.map((theme) => ThemeTag(theme: theme)).toList(),
            ),
          ],
        ),
      ),
    );
  }
}