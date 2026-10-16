// ignore_for_file: public_member_api_docs

import 'package:flutter/widgets.dart';
import 'package:idle_logout/idle_logout.dart';

class IdleLogoutSettings extends ChangeNotifier {
  Duration _timeout = const Duration(seconds: 30);
  bool _enabled = false;

  Duration get timeout => _timeout;
  bool get enabled => _enabled;

  void toggleTimeout() {
    _timeout = _timeout == const Duration(seconds: 30) ? const Duration(seconds: 10) : const Duration(seconds: 30);
    notifyListeners();
  }

  void toggleEnabled() {
    _enabled = !_enabled;
    notifyListeners();
  }

  void reset() {
    _timeout = const Duration(seconds: 30);
    _enabled = false;
    notifyListeners();
  }
}

class LocalStorage {
  static bool isLockedOut = false;
  static bool userLoggedIn = true;
  static final controller = IdleLogoutController();
  static final settings = IdleLogoutSettings();
}
