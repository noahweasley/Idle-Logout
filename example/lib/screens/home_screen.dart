import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Welcome! Click anywhere on the screen or drag finger '
          'across the screen to stay logged in.',
        ),
      ),
    );
  }
}
