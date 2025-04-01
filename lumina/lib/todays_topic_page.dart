import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TodaysTopicPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Today's Topic", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 30),
              Text(
                "Gender Inequality",
                style: GoogleFonts.baloo2(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepOrange,
                ),
              ),
              SizedBox(height: 20),
              Text("Featured Stories", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              // Placeholder list of best stories
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: 3,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text("Story Title ${index + 1}"),
                      subtitle: Text("Brief description of the story..."),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}