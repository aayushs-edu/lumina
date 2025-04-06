import 'package:flutter/material.dart';
import 'widgets/navbar.dart';

class DataCenterPage extends StatelessWidget {
  final List<Map<String, String>> stories = [
    {"country": "USA", "story": "Story from USA"},
    {"country": "India", "story": "Story from India"},
    {"country": "Brazil", "story": "Story from Brazil"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'dataCenter'),
      ),
      body: ListView.builder(
        itemCount: stories.length,
        itemBuilder: (context, index) {
          var story = stories[index];
          return Card(
            margin: EdgeInsets.all(8),
            child: ListTile(
              title: Text("${story['country']}"),
              subtitle: Text("${story['story']}"),
            ),
          );
        },
      ),
    );
  }
}