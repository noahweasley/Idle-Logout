import 'dart:async' show Timer, unawaited;

import 'package:flutter/foundation.dart' show AsyncValueGetter, kDebugMode;
import 'package:flutter/widgets.dart';

/// {@template idle_logout}
/// A Flutter widget for handling automatic user logout after inactivity.
///
/// ## Example
///
/// ```dart
/// IdleLogout(
///   timeout: const Duration(minutes: 5),
///   isLoggedIn: () => authService.isLoggedIn,
///   isLockedOut: () => authService.isLockedOut,
///   lockedOutAction: () async {
///     await authService.logout();
///     // For example: navigate to login screen
///     Navigator.of(context).pushReplacementNamed('/login');
///   },
///   child: MyHomePage(),
/// )
/// ```
///
/// Place [IdleLogout] high in your widget tree (e.g. above `MaterialApp` or
/// your main page) to monitor app lifecycle events and reset the idle timer.
/// {@endtemplate}
class IdleLogout extends StatefulWidget {
  /// {@macro idle_logout}
  const IdleLogout({
    required this.child,
    required this.isLoggedIn,
    required this.isLockedOut,
    required this.lockedOutAction,
    required this.timeout,
    super.key,
  });

  /// The widget to watch for activity
  final Widget child;

  /// callback to check if we are logged in
  final ValueGetter<bool> isLoggedIn;

  /// callback to check if we are locked out
  final ValueGetter<bool> isLockedOut;

  /// timeout
  final Duration timeout;

  /// action to be performed when we are ready to lock-out the user
  final AsyncValueGetter<void> lockedOutAction;

  @override
  State<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends State<IdleLogout> with WidgetsBindingObserver {
  Timer? _idleTimer;
  final Duration _pauseThreshold = const Duration(seconds: 30);
  DateTime? _pausedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint('Lifecycle changed → $state at ${DateTime.now()}');

    if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final awayFor = DateTime.now().difference(_pausedAt!);

        if (kDebugMode) {
          debugPrint('App was away for: $awayFor');
        }

        if (awayFor > _pauseThreshold) {
          debugPrint('Away > $_pauseThreshold → locking user');
          unawaited(_handleIdle());
        } else {
          debugPrint('Away < $_pauseThreshold → resume without locking');
          _resetTimer();
        }

        _pausedAt = null;
      } else {
        _resetTimer();
      }
    } else if ([
      AppLifecycleState.paused,
      AppLifecycleState.inactive,
    ].contains(state)) {
      // Only set the first time we go background
      _pausedAt ??= DateTime.now();

      if (kDebugMode) {
        debugPrint('App paused/inactive at $_pausedAt');
      }

      _idleTimer?.cancel();
    } else if (state == AppLifecycleState.hidden) {
      // Rarely even used, but keep for completeness
      _pausedAt ??= DateTime.now();
      debugPrint('App hidden at $_pausedAt');
    }
  }

  @override
  void dispose() {
    debugPrint('IdleLogout disposed at ${DateTime.now()}');
    WidgetsBinding.instance.removeObserver(this);
    _idleTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (kDebugMode) {
      debugPrint('IdleLogout initialized, timeout = $widget.timeout');
    }

    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (kDebugMode) {
          debugPrint('User interacted → reset idle timer');
        }

        _resetTimer();
      },
      child: widget.child,
    );
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.timeout, _handleIdle);

    if (kDebugMode) {
      debugPrint('Idle timer started/reset at ${DateTime.now()} for $widget.timeout');
    }
  }

  Future<void> _handleIdle() async {
    if (!mounted) return;
    debugPrint('Idle handler fired at ${DateTime.now()}');

    final loggedIn = widget.isLoggedIn();
    final locked = widget.isLockedOut();

    if (loggedIn && !locked) {
      if (kDebugMode) {
        debugPrint('User logged in and not locked out → locking now...');
      }

      if (mounted) {
        await widget.lockedOutAction();
      }
    } else {
      if (kDebugMode) {
        debugPrint('Either no user logged in or already locked → no action');
      }
    }
  }
}
