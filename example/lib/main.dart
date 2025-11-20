import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';

import '../../screens/home_screen.dart';
import 'screens/lock_screen.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return IdleLogout(
      pauseThreshold: const Duration(seconds: 15),
      timeout: const Duration(seconds: 10),
      isLoggedIn: () => true,
      isLockedOut: () => false,
      lockedOutAction: () async {
        debugPrint('User logged out due to inactivity');

        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const LockScreen(),
          ),
        );
      },
      child: MaterialApp(navigatorKey: navigatorKey, home: const HomeScreen()),
    );
  }
}
