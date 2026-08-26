import 'dart:async';

import 'package:idle_logout/idle_logout.dart' show IdleLogout;
import 'package:idle_logout/src/enums.dart';

/// Controls an [IdleLogout] timer.
///
/// The controller does not contain or configure the timer. It only emits
/// commands that are handled by the [IdleLogout] widget.
class IdleLogoutController {
  /// Creates an [IdleLogoutController].
  IdleLogoutController();

  final _commandController = StreamController<IdleLogoutCommand>.broadcast(sync: true);

  /// Stream of commands sent to [IdleLogout].
  Stream<IdleLogoutCommand> get commandStream => _commandController.stream;

  /// Pauses the idle timer.
  void pause() {
    _commandController.add(IdleLogoutCommand.pause);
  }

  /// Starts the idle timer.
  void start() {
    _commandController.add(IdleLogoutCommand.start);
  }

  /// Resumes the idle timer.
  void resume() {
    _commandController.add(IdleLogoutCommand.resume);
  }

  /// Stops the idle timer.
  void stop() {
    _commandController.add(IdleLogoutCommand.stop);
  }

  /// Resets the idle timer.
  void reset() {
    _commandController.add(IdleLogoutCommand.reset);
  }

  /// Disposes the controller.
  void dispose() {
    _commandController.close();
  }
}
