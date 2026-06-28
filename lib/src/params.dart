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
    required this.lockedOutAction,
    required this.timeout,
    this.debug = false,
    this.backgroundTimeout,
  });

  /// callback to check if we are locked out
  final AsyncValueGetter<bool> isLockedOut;

  /// callback to check if we are logged in
  final AsyncValueGetter<bool> isLoggedIn;

  /// action to be performed when we are ready to lock-out the user
  final AsyncValueGetter<void> lockedOutAction;

  /// duration after which we consider the app paused for too long,
  /// default is 30 seconds
  final Duration? backgroundTimeout;

  /// timeout
  final Duration timeout;

  /// if debug mode should be enabled
  final bool debug;
}
