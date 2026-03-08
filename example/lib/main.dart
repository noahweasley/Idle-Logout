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
      isLoggedIn: isLoggedIn,
      isLockedOut: isLockedOut,
      lockedOutAction: lockedOutAction,
      child: MaterialApp(navigatorKey: navigatorKey, home: const HomeScreen()),
    );
  }
}

Future<void> lockedOutAction() async {
  debugPrint('User logged out due to inactivity');

  await navigatorKey.currentState?.pushReplacement(
    MaterialPageRoute<void>(builder: (_) => const LockScreen()),
  );
}

Future<bool> isLoggedIn() async {
  // write your in-app logic for checking if your app is logged in
  return true;
}

Future<bool> isLockedOut() async {
  // write your in-app logic for checking if your app is locked out
  return false;
}
