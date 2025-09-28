import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';

import '../screens/home_screen.dart';
import '../screens/other_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: IdleLogout(
        timeout: const Duration(seconds: 10),
        isLoggedIn: () => true, // Replace with your auth logic
        isLockedOut: () => false,
        lockedOutAction: () async {
          debugPrint('User logged out due to inactivity');

          await Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => const OtherScreen(),
            ),
          );
        },
        child: const HomeScreen(),
      ),
    );
  }
}
