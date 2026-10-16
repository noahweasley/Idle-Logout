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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalStorage.settings,
      builder: (context, child) {
        return IdleLogout(
          controller: LocalStorage.controller,
          params: Params(
            enabled: LocalStorage.settings.enabled,
            debug: true,
            backgroundTimeout: const Duration(seconds: 30),
            timeout: LocalStorage.settings.timeout,
            isLoggedIn: isLoggedIn,
            isLockedOut: isLockedOut,
            onLockedOut: onLockedOut,
          ),
          child: child!,
        );
      },
      child: MaterialApp(navigatorKey: navigatorKey, home: const HomeScreen()),
    );
  }

  Future<void> onLockedOut() async {
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
