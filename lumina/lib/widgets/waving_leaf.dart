import 'package:flutter/material.dart';

class WavingLeaf extends StatefulWidget {
  final String assetPath;
  final double width;
  final double initialAngle; // starting rotation angle in radians
  final double amplitude; // maximum additional rotation in radians
  final Duration duration; // cycle duration

  const WavingLeaf({
    Key? key,
    required this.assetPath,
    required this.width,
    this.initialAngle = 0,
    this.amplitude = 0.1,
    this.duration = const Duration(seconds: 2),
  }) : super(key: key);

  @override
  _WavingLeafState createState() => _WavingLeafState();
}

class _WavingLeafState extends State<WavingLeaf>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Oscillate the rotation from initialAngle - amplitude to initialAngle + amplitude
        double waveRotation =
            widget.initialAngle + widget.amplitude * (2 * _controller.value - 1);
        return Transform.rotate(
          angle: waveRotation,
          child: child,
        );
      },
      child: Image.asset(
        widget.assetPath,
        width: widget.width,
      ),
    );
  }
}