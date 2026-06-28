// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            right: 0,
            left: 0,
            top: 100,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
                    child: FlutterLogo(size: MediaQuery.of(context).size.width / 3),
                  ),
                  const Text(
                    'Welcome! Click anywhere on the screen or drag your finger '
                    'across the screen to stay logged in.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  const TextField(
                    decoration: InputDecoration(labelText: 'Enter something', border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
