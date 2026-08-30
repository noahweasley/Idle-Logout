import 'dart:async' show StreamSubscription, Timer, unawaited;
import 'dart:developer' show log;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'package:idle_logout/src/controller.dart';
import 'package:idle_logout/src/enums.dart' show IdleLogoutCommand, Mode;
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

  /// Internal clock for testing.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  /// The widget to watch for activity.
  final Widget child;

  /// Optional controller for programmatic control.
  final IdleLogoutController? controller;

  /// Configuration parameters.
  final Params params;

  @override
  State<IdleLogout> createState() => _IdleLogoutState();
}

class _IdleLogoutState extends State<IdleLogout> with WidgetsBindingObserver {
  late final IdleLogoutController controller;

  late final Duration _backgroundTimeout;
  StreamSubscription<IdleLogoutCommand>? _controllerSubscription;
  final FocusNode _focusNode = FocusNode();
  Timer? _idleTimer;
  Timer? pausedTimer;
  bool _isPaused = false;
  bool _isStopped = false;
  DateTime? _pausedAt;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    final now = IdleLogout.now();
    _log('Lifecycle changed; $state at $now');

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
    _log('Disposed at ${IdleLogout.now()}');

    controller.stop();
    _controllerSubscription?.cancel();
    _idleTimer?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    if (_ownsController) {
      controller.dispose();
    }

    _focusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _backgroundTimeout = widget.params.backgroundTimeout ?? const Duration(seconds: 30);

    _initializeController();
    WidgetsBinding.instance.addObserver(this);

    _log('Initialized; timeout = ${widget.params.timeout}');

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
        onPointerDown: _onPointerDown,
        child: widget.child,
      ),
    );
  }

  bool get _ownsController => widget.controller == null;

  void _initializeController() {
    controller = widget.controller ?? IdleLogoutController();
    _controllerSubscription = controller.commandStream.listen(
      _handleControllerCommand,
    );
  }

  void _handleControllerCommand(IdleLogoutCommand command) {
    switch (command) {
      case IdleLogoutCommand.pause:
        _pauseTimer();

      case IdleLogoutCommand.start:
        _startTimer();

      case IdleLogoutCommand.resume:
        _resumeTimer();

      case IdleLogoutCommand.stop:
        _stopTimer();

      case IdleLogoutCommand.reset:
        _resetTimer();
    }
  }

  void _onPointerDown(PointerDownEvent _) {
    if (_isPaused) return;

    _log('User interacted; resetting idle timer');
    _resetTimer();
  }

  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent && !_isPaused && !_isStopped) {
      _log('Keyboard interaction; resetting idle timer');
      _resetTimer();
    }

    return KeyEventResult.ignored;
  }

  void _pauseTimer() {
    if (_isPaused || _isStopped) {
      _log('Cannot pause timer because timer is already paused/stopped', mode: Mode.info);
      return;
    }

    final now = IdleLogout.now();

    _isPaused = true;
    _pausedAt ??= now;
    _cancelTimer();
    _log('Paused at $now');
  }

  void _startTimer() {
    if (_isPaused) {
      _log('Cannot start a paused timer, please use controller.resume() instead');
      return;
    }

    final now = IdleLogout.now();

    _isStopped = false;
    _isPaused = false;
    _pausedAt = null;

    _log('Started at $now');
    _resetTimer();
  }

  void _resumeTimer() {
    final now = IdleLogout.now();

    _log('Resumed at $now');

    _isStopped = false;
    _isPaused = false;

    final pausedAt = _pausedAt;
    _pausedAt = null;

    if (pausedAt != null) {
      final awayFor = now.difference(pausedAt);
      _log('Paused/away for: $awayFor');

      if (awayFor > _backgroundTimeout) {
        _log('Away > $_backgroundTimeout; locking user');
        unawaited(_handleIdle());
        return;
      }
    }

    _log('Away <= $_backgroundTimeout; resuming idle timer');
    // TODO: fix timer. Timer shouldn't be reset, but resumed from wherever time stopped
    _resetTimer();
  }

  void _stopTimer() {
    final now = IdleLogout.now();

    _cancelTimer();

    _isPaused = false;
    _isStopped = true;
    _pausedAt = null;

    _log('Stopped at $now');
  }

  void _resetTimer() {
    _cancelTimer();

    _idleTimer = Timer(
      widget.params.timeout,
      _handleIdle,
    );

    _log('Timer started/reset at ${IdleLogout.now()}');
  }

  void _cancelTimer() {
    _idleTimer?.cancel();
    _idleTimer = null;
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

      if (mounted) {
        await params.onLockedOut();
      }

      return;
    }

    _log('Either no user logged in or already locked; no action');
    _stopTimer();
  }

  void _log(String message, {Mode mode = Mode.normal}) {
    if (kDebugMode && widget.params.debug) {
      if (mode == Mode.normal) {
        debugPrint('[IdleLogout]: $message');
      } else {
        log('[IdleLogout]: $message');
      }
    }
  }
}
