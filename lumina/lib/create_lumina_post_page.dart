import 'package:flutter/material.dart';

class CreateLuminaPostPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create a Lumina Post", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "AI will generate an image,\ncaption, and hashtags.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: Colors.deepOrange,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}