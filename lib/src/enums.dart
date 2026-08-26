import 'package:idle_logout/src/controller.dart' show IdleLogoutController;

/// Commands supported by [IdleLogoutController].
enum IdleLogoutCommand {
  /// Pause the timer.
  pause,

  /// Start the timer.
  start,

  /// Resume the timer.
  resume,

  /// Stop the timer.
  stop,

  /// Reset the timer.
  reset,
}
