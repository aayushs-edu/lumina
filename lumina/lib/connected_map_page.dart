import 'package:flutter/material.dart';
import 'package:lumina/lumina_lens_map.dart'; // adjust path if needed

class InteractiveAnimatedMapPage extends StatelessWidget {
  const InteractiveAnimatedMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Important!
      appBar: AppBar(
        title: const Text('Animated World Map'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Center(
        child: LuminaLensWorldMap(),
      ),
    );
  }
}