// ignore_for_file: public_member_api_docs

import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';
import 'package:idle_logout_sample/screens/home_screen.dart';
import 'package:idle_logout_sample/screens/lock_screen.dart';
import 'package:idle_logout_sample/utils.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return IdleLogout(
      params: Params(
        debug: true,
        backgroundTimeout: const Duration(seconds: 15),
        timeout: const Duration(seconds: 10),
        isLoggedIn: isLoggedIn,
        isLockedOut: isLockedOut,
        lockedOutAction: lockedOutAction,
      ),
      child: MaterialApp(navigatorKey: navigatorKey, home: const HomeScreen()),
    );
  }

  Future<void> lockedOutAction() async {
    debugPrint('User logged out due to inactivity');
    LocalStorage.isLockedOut = true;

    await navigatorKey.currentState?.pushReplacement(MaterialPageRoute<void>(builder: (_) => const LockScreen()));
  }

  Future<bool> isLoggedIn() async {
    // write your in-app logic for checking if your app is logged in
    return LocalStorage.userLoggedIn;
  }

  Future<bool> isLockedOut() async {
    // write your in-app logic for checking if your app is locked out
    return LocalStorage.isLockedOut;
  }
}
