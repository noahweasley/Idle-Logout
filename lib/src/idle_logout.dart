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
/// application through [Params.onLockedOut], allowing the application to
/// decide what action should be taken.
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
/// - Otherwise, idle monitoring resumes and the timer continues from the
///   remaining duration.
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

  /// The widget to watch for activity.
  final Widget child;

  /// Optional controller for programmatic control.
  final IdleLogoutController? controller;

  /// Configuration parameters.
  final Params params;

  /// Internal clock for testing.
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  @override
  State<IdleLogout> createState() => _IdleLogoutState();
}

/// State responsible for monitoring user activity, application lifecycle
/// changes, and the idle timeout.
class _IdleLogoutState extends State<IdleLogout> with WidgetsBindingObserver {
  /// Maximum amount of time the application can remain in the background
  /// before the user is considered inactive.
  late final Duration backgroundTimeout;

  /// Controller used to receive idle logout commands.
  late final IdleLogoutController controller;

  /// Subscription to commands emitted by the [IdleLogoutController].
  StreamSubscription<IdleLogoutCommand>? controllerSubscription;

  /// Timer responsible for triggering the idle callback.
  Timer? idleTimer;

  /// Whether idle monitoring is currently paused.
  bool isPaused = false;

  /// Whether idle monitoring has been stopped.
  bool isStopped = false;

  /// Timestamp recorded when idle monitoring was paused.
  DateTime? pausedAt;

  /// Duration remaining on the idle timer.
  Duration? previousTimeout;

  /// Timestamp at which the current idle timer started.
  DateTime? timerStartedAt;

  /// Focus node used to listen for keyboard activity.
  final FocusNode _focusNode = FocusNode();

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
    unawaited(controllerSubscription?.cancel());

    _cancelTimer();

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

    previousTimeout = widget.params.timeout;

    backgroundTimeout =
        widget.params.backgroundTimeout ?? const Duration(seconds: 30);

    _initializeController();

    WidgetsBinding.instance.addObserver(this);

    _log('Initialized; timeout = ${widget.params.timeout}');

    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.params.ignorePointer) return widget.child;

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

  /// Returns the amount of time remaining on the current idle timer.
  ///
  /// The remaining duration is calculated from the timestamp at which the
  /// current timer started.
  Duration get remainingTime {
    final startedAt = timerStartedAt;

    if (startedAt == null) {
      return previousTimeout ?? widget.params.timeout;
    }

    final elapsed = IdleLogout.now().difference(startedAt);
    final remaining = (previousTimeout ?? widget.params.timeout) - elapsed;

    if (remaining <= Duration.zero) {
      return Duration.zero;
    }

    return remaining;
  }

  /// Whether the widget created and owns the controller.
  bool get _ownsController => widget.controller == null;

  /// Initializes the controller and listens for commands.
  void _initializeController() {
    controller = widget.controller ?? IdleLogoutController();

    controllerSubscription = controller.commandStream.listen(
      _handleControllerCommand,
    );
  }

  /// Handles commands received from the [IdleLogoutController].
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

  /// Handles pointer interaction by resetting the idle timer.
  void _onPointerDown(PointerDownEvent _) {
    if (isPaused || isStopped) return;

    _log('User interacted; resetting idle timer');
    _resetTimer();
  }

  /// Handles keyboard interaction by resetting the idle timer.
  KeyEventResult _onKeyEvent(FocusNode _, KeyEvent event) {
    if (event is KeyDownEvent && !isPaused && !isStopped) {
      _log('Keyboard interaction; resetting idle timer');
      _resetTimer();
    }

    return KeyEventResult.ignored;
  }

  /// Pauses the idle timer and stores the remaining duration.
  void _pauseTimer() {
    if (isPaused || isStopped) {
      _log(
        'Cannot pause timer because timer is already paused/stopped',
        mode: Mode.info,
      );
      return;
    }

    final now = IdleLogout.now();
    final remaining = remainingTime;

    previousTimeout = remaining;
    timerStartedAt = null;
    pausedAt ??= now;
    isPaused = true;

    _cancelTimer();

    _log('Paused at $now; remaining timeout = $previousTimeout');
  }

  /// Starts idle monitoring from the configured timeout.
  void _startTimer() {
    if (isPaused) {
      _log(
        'Cannot start a paused timer, please use controller.resume() instead',
      );
      return;
    }

    final now = IdleLogout.now();

    isStopped = false;
    isPaused = false;
    pausedAt = null;

    _log('Started at $now');
    _resetTimer();
  }

  /// Resumes idle monitoring after the application returns to the foreground.
  ///
  /// If the application has been away longer than [backgroundTimeout], the
  /// idle handler is invoked immediately. Otherwise, the previously remaining
  /// idle duration is restored.
  void _resumeTimer() {
    final now = IdleLogout.now();

    _log('Resumed at $now');

    isStopped = false;
    isPaused = false;

    final pausedAt = this.pausedAt;
    this.pausedAt = null;

    if (pausedAt != null) {
      final awayFor = now.difference(pausedAt);

      _log('Paused/away for: $awayFor');

      if (awayFor > backgroundTimeout) {
        _log('Away > $backgroundTimeout; locking user');
        unawaited(_handleIdle());
        return;
      }
    }

    final timeout = previousTimeout ?? widget.params.timeout;

    _log(
      'Away <= $backgroundTimeout; resuming idle timer with '
      '$timeout remaining',
    );

    _continueTimer();
  }

  /// Stops idle monitoring and clears the current timer state.
  void _stopTimer() {
    final now = IdleLogout.now();

    _cancelTimer();

    isPaused = false;
    isStopped = true;
    pausedAt = null;
    timerStartedAt = null;
    previousTimeout = null;

    _log('Stopped at $now');
  }

  /// Resets the idle timer to the full configured timeout.
  void _resetTimer() {
    _cancelTimer();

    previousTimeout = widget.params.timeout;
    timerStartedAt = IdleLogout.now();

    idleTimer = Timer(
      widget.params.timeout,
      _handleIdle,
    );

    _log(
      'Timer started/reset at $timerStartedAt; '
      'timeout = ${widget.params.timeout}',
    );
  }

  /// Continues the idle timer using the previously remaining duration.
  void _continueTimer() {
    _cancelTimer();

    final timeout = previousTimeout ?? widget.params.timeout;

    if (timeout <= Duration.zero) {
      unawaited(_handleIdle());
      return;
    }

    timerStartedAt = IdleLogout.now();

    idleTimer = Timer(
      timeout,
      _handleIdle,
    );

    _log(
      'Timer continued at $timerStartedAt; '
      'remaining timeout = $timeout',
    );
  }

  /// Cancels the active idle timer.
  void _cancelTimer() {
    idleTimer?.cancel();
    idleTimer = null;
  }

  /// Handles an idle timeout.
  ///
  /// The user is locked out only when the user is logged in and is not
  /// already locked out.
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

  /// Logs diagnostic information when debugging is enabled.
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
