import 'package:flutter/material.dart';
import 'widgets/navbar.dart';

class CreateLuminaPostPage extends StatefulWidget {
  @override
  _CreateLuminaPostPageState createState() => _CreateLuminaPostPageState();
}

class _CreateLuminaPostPageState extends State<CreateLuminaPostPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: LuminaNavbar(currentPage: 'createLuminaPost'),
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