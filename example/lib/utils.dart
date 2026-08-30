// ignore_for_file: public_member_api_docs

import 'package:idle_logout/idle_logout.dart';

class LocalStorage {
  static bool isLockedOut = false;
  static bool userLoggedIn = true;
  static final controller = IdleLogoutController();
}
