import 'package:flutter/foundation.dart';
import 'package:idle_logout/idle_logout.dart';

/// Configuration parameters for [IdleLogout].
///
/// Defines session state checks, inactivity timeout behavior, and
/// the action to execute when the user is considered idle.
class Params {
  /// Creates configuration for [IdleLogout].
  Params({
    required this.isLoggedIn,
    required this.isLockedOut,
    required this.onLockedOut,
    required this.timeout,
    this.debug = false,
    this.backgroundTimeout,
  });

  /// callback to check if we are locked out
  final AsyncOrBoolGetter isLockedOut;

  /// callback to check if we are logged in
  final AsyncOrBoolGetter isLoggedIn;

  /// action to be performed when we are ready to lock-out the user
  final AsyncValueGetter<void> onLockedOut;

  /// duration after which we consider the app paused for too long,
  /// default is 30 seconds
  final Duration? backgroundTimeout;

  /// timeout
  final Duration timeout;

  /// if debug mode should be enabled
  final bool debug;
}
