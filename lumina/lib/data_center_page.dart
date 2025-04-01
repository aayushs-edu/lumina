import 'package:flutter/material.dart';

class DataCenterPage extends StatelessWidget {
  final List<Map<String, String>> stories = [
    {"country": "USA", "story": "Story from USA"},
    {"country": "India", "story": "Story from India"},
    {"country": "Brazil", "story": "Story from Brazil"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Data Center", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
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