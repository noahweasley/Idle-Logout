import 'dart:async' show StreamSubscription, Timer, unawaited;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:idle_logout/src/controller.dart';
import 'package:idle_logout/src/enums.dart' show IdleLogoutCommand;
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
/// [Params.onLockedOut] is invoked if:
/// - [Params.isLoggedIn] returns `true`.
/// - [Params.isLockedOut] returns `false`.
///
/// The widget itself does not perform any locking, logout, navigation,
/// or authentication-related operations. Instead, it notifies the host
/// application through [Params.onLockedOut], allowing the application
/// to decide what action should be taken.
///
/// ## App lifecycle handling
///
/// When the app moves to the background (`paused`, `inactive`, or `hidden`),
/// the idle timer is suspended and the current timestamp is recorded.
///
/// When the app returns to the foreground:
///
/// - If the time spent away exceeds [Params.backgroundTimeout],
///   [Params.onLockedOut] is invoked immediately.
/// - Otherwise, idle monitoring resumes and the timer is restarted.
///
/// ## Example
///
/// ```dart
/// final controller = IdleLogoutController();
///
/// IdleLogout(
///   controller: controller,
///   params: Params(
///     timeout: const Duration(minutes: 5),
///     isLoggedIn: authService.isLoggedIn,
///     isLockedOut: authService.isLockedOut,
///     onLockedOut: () async {
///       await authService.lockSession();
///     },
///   ),
///   child: const MyHomePage(),
/// );
///
/// controller.pause();
/// controller.start();
/// controller.resume();
/// controller.stop();
/// controller.reset();
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
    this.controller,
    super.key,
  });

  /// Internal clock for testing
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// The widget to watch for activity
  final Widget child;

  /// Optional controller to allow programmatic control of the idle timer.
  final IdleLogoutController? controller;

  /// Parameters
  final Params params;

  @override
  State<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends State<IdleLogout> with WidgetsBindingObserver {
  late final IdleLogoutController controller;

  late final Duration _backgroundTimeout;
  StreamSubscription<IdleLogoutCommand>? _controllerSubscription;
  final _focusNode = FocusNode();
  Timer? _idleTimer;
  bool _isPaused = false;
  bool _isStopped = false;
  DateTime? _pausedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _log('Lifecycle changed; $state at ${IdleLogout.now()}');

    switch (state) {
      case AppLifecycleState.resumed:
        controller.resume();

      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
        controller.pause();

      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    _log('disposed at ${IdleLogout.now()}');

    controller.stop();
    _controllerSubscription?.cancel();
    WidgetsBinding.instance.removeObserver(this);

    if (_hasOwnController) {
      controller.dispose();
    }

    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _backgroundTimeout = widget.params.backgroundTimeout ?? const Duration(seconds: 30);
    _initController();
    WidgetsBinding.instance.addObserver(this);
    _log('IdleLogout initialized; timeout = ${widget.params.timeout}');

    controller.start();
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
          if (_isPaused || _isStopped) return;
          _log('User interacted; reset idle timer');
          _onResetTimer();
        },
        child: widget.child,
      ),
    );
  }

  bool get _hasOwnController => widget.controller == null;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent) {
      if (_isPaused || _isStopped) return KeyEventResult.ignored;
      _log('Keyboard interaction; reset idle timer');
      _onResetTimer();
    }

    return KeyEventResult.ignored;
  }

  void _log(String message) {
    final isDebugEnabled = kDebugMode && widget.params.debug;

    if (isDebugEnabled) {
      // ignore: no_runtimetype_tostring
      debugPrint('[$runtimeType]: $message');
    }
  }

  void _initController() {
    controller = widget.controller ?? IdleLogoutController();

    _controllerSubscription = controller.commandStream.listen((command) {
      switch (command) {
        case IdleLogoutCommand.pause:
          _onPauseTimer();

        case IdleLogoutCommand.start:
        case IdleLogoutCommand.resume:
          _onResumeTimer();

        case IdleLogoutCommand.stop:
          _onStopTimer();

        case IdleLogoutCommand.reset:
          _onResetTimer();
      }
    });
  }

  void _onPauseTimer() {
    if (_isPaused || _isStopped) return;
    _log('paused at ${IdleLogout.now()}');

    _isPaused = true;
    _pausedAt ??= IdleLogout.now();

    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void _onResumeTimer() {
    if (_isStopped) {
      return;
    }

    _log('resumed at ${IdleLogout.now()}');

    if (!_isPaused) {
      _onResetTimer();
      return;
    }

    _isPaused = false;

    if (_pausedAt != null) {
      final awayFor = IdleLogout.now().difference(_pausedAt!);
      _pausedAt = null;

      _log('Paused/away for: $awayFor');

      if (awayFor > _backgroundTimeout) {
        _log('Away > $_backgroundTimeout; locking user');
        unawaited(_handleIdle());
        return;
      }
    }

    _log('Away <= $_backgroundTimeout; resuming idle timer');
    _onResetTimer();
  }

  void _onStopTimer() {
    _log('stopped at ${IdleLogout.now()}');

    _idleTimer?.cancel();
    _idleTimer = null;

    _isPaused = false;
    _isStopped = true;
    _pausedAt = null;
  }

  void _onResetTimer() {
    if (_isStopped || _isPaused) {
      return;
    }

    _idleTimer?.cancel();

    _idleTimer = Timer(
      widget.params.timeout,
      _handleIdle,
    );

    _log('Idle timer started/reset at ${IdleLogout.now()}');
  }

  Future<void> _handleIdle() async {
    if (!mounted) return;
    final params = widget.params;

    _log('Idle handler fired at ${IdleLogout.now()}');

    final loggedIn = await params.isLoggedIn();
    final locked = await params.isLockedOut();

    if (!mounted) return;

    if (loggedIn && !locked) {
      _log('User logged in and not locked out; locking now...');
      controller.stop();
      await params.onLockedOut();
    } else {
      _log('Either no user logged in or already locked; no action');

      if (!_isStopped && !_isPaused) {
        _onResetTimer();
      }
    }
  }
}
