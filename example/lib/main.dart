import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';

import '../../screens/home_screen.dart';
import '../../screens/other_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      home: IdleLogout(
        timeout: const Duration(seconds: 4),
        isLoggedIn: () => true,
        isLockedOut: () => false,
        lockedOutAction: () async {
          debugPrint('User logged out due to inactivity');

          navigatorKey.currentState?.pushReplacement(
            MaterialPageRoute<void>(builder: (BuildContext context) => const OtherScreen()),
          );
        },
        child: const HomeScreen(),
      ),
    );
  }
}
