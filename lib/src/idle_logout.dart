import 'dart:async' show Timer, unawaited;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:idle_logout/src/params.dart';

/// {@template idle_logout}
/// A widget that monitors user inactivity and notifies your application when
/// an idle timeout occurs.
///
/// `IdleLogout` listens for user interactions and app lifecycle changes,
/// tracking how long the user has been inactive.
///
/// Activity that resets the idle timer includes:
/// - Touch and pointer interactions.
/// - Keyboard input.
/// - Returning to the app after a short background period.
///
/// When the configured [Params.timeout] is reached without activity,
/// [Params.lockedOutAction] is invoked if:
/// - [Params.isLoggedIn] returns `true`.
/// - [Params.isLockedOut] returns `false`.
///
/// The widget itself does not perform any locking, logout, navigation,
/// or authentication-related operations. Instead, it notifies the host
/// application through [Params.lockedOutAction], allowing the application
/// to decide what action should be taken.
///
/// ## App lifecycle handling
///
/// When the app moves to the background (`paused`, `inactive`, or `hidden`),
/// the idle timer is suspended and the current timestamp is recorded.
///
/// When the app returns to the foreground:
///
/// - If the time spent away exceeds [Params.pauseThreshold],
///   [Params.lockedOutAction] is invoked immediately.
/// - Otherwise, idle monitoring resumes and the timer is restarted.
///
/// ## Example
///
/// ```dart
/// IdleLogout(
///   params: Params(
///     timeout: const Duration(minutes: 5),
///     isLoggedIn: authService.isLoggedIn,
///     isLockedOut: authService.isLockedOut,
///     lockedOutAction: () async {
///       await authService.lockSession();
///     },
///   ),
///   child: const MyHomePage(),
/// )
/// ```
///
/// ## Placement
///
/// Place this widget high in your widget tree so activity throughout the
/// application can be observed.
/// {@endtemplate}
class IdleLogout extends StatefulWidget {
  /// {@macro idle_logout}
  const IdleLogout({
    required this.params,
    required this.child,
    super.key,
  });

  /// The widget to watch for activity
  final Widget child;

  /// Parameters
  final Params params;

  /// Internal clock for testing
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @override
  State<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends State<IdleLogout> with WidgetsBindingObserver {
  final _focusNode = FocusNode();
  Timer? _idleTimer;
  late final Duration _pauseThreshold;
  DateTime? _pausedAt;
  late final bool isDebugEnabled;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (isDebugEnabled) {
      debugPrint('Lifecycle changed; $state at ${IdleLogout.now()}');
    }

    if (state == AppLifecycleState.resumed) {
      if (_pausedAt != null) {
        final awayFor = IdleLogout.now().difference(_pausedAt!);

        if (isDebugEnabled) {
          debugPrint('App was away for: $awayFor');
        }

        if (awayFor > _pauseThreshold) {
          if (isDebugEnabled) debugPrint('Away > $_pauseThreshold; locking user');
          unawaited(_handleIdle());
        } else {
          if (isDebugEnabled) {
            debugPrint('Away < $_pauseThreshold; resume without locking');
          }

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
      _pausedAt ??= IdleLogout.now();

      if (isDebugEnabled) {
        debugPrint('App paused/inactive at $_pausedAt');
      }

      _idleTimer?.cancel();
    } else if (state == AppLifecycleState.hidden) {
      // Rarely even used, but keep for completeness
      _pausedAt ??= IdleLogout.now();

      if (isDebugEnabled) {
        debugPrint('App hidden at $_pausedAt');
      }
    }
  }

  @override
  void dispose() {
    if (isDebugEnabled) {
      debugPrint('IdleLogout disposed at ${IdleLogout.now()}');
    }

    WidgetsBinding.instance.removeObserver(this);
    _stopTimer();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    final params = widget.params;
    isDebugEnabled = kDebugMode && params.debug;

    super.initState();
    _pauseThreshold = params.pauseThreshold ?? const Duration(seconds: 30);

    if (isDebugEnabled) {
      debugPrint('IdleLogout initialized, timeout = ${params.timeout}');
    }

    WidgetsBinding.instance.addObserver(this);
    _resetTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: _onKeyEvent,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          if (isDebugEnabled) {
            debugPrint('User interacted; reset idle timer');
          }

          _resetTimer();
        },
        child: widget.child,
      ),
    );
  }

  void _stopTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _resetTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(widget.params.timeout, _handleIdle);

    if (isDebugEnabled) {
      debugPrint('Idle timer started/reset at ${IdleLogout.now()}');
    }
  }

  Future<void> _handleIdle() async {
    final params = widget.params;

    if (!mounted) return;

    if (isDebugEnabled) {
      debugPrint('Idle handler fired at ${IdleLogout.now()}');
    }

    final loggedIn = await params.isLoggedIn();
    final locked = await params.isLockedOut();

    if (loggedIn && !locked) {
      if (isDebugEnabled) {
        debugPrint('User logged in and not locked out; locking now...');
      }

      _stopTimer();

      if (mounted) {
        await params.lockedOutAction();
      }
    } else {
      if (isDebugEnabled) {
        debugPrint('Either no user logged in or already locked; no action');
      }
    }
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (isDebugEnabled) {
        debugPrint('Keyboard interaction; reset idle timer');
      }

      _resetTimer();
    }

    return KeyEventResult.ignored;
  }
}
