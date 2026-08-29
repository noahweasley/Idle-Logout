<h1 align="center">Idle Logout</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Dart-≥3.0-blue?logo=dart&logoColor=white" alt="Minimum Dart Version" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-009688?logo=flutter&logoColor=white&color=009688" alt="Supported Platforms" />
  <img src="https://img.shields.io/badge/Style-Very%20Good%20CLI-purple?logo=very-good&logoColor=white" alt="Very Good CLI" />
  <img src="https://img.shields.io/badge/Test%20coverage-98.7%25-green" alt="Test Coverage" />
</p>

<p align="center">
  A Flutter package for monitoring user inactivity and triggering a configurable lock or logout callback. Designed for applications that require session security, including banking, healthcare, and enterprise applications.
</p>

<br/>

<p align="center">
  <img src="demo/demo.gif" alt="Idle Logout Demo" width="400" />
</p>

---

## Features

- Tracks inactivity from pointer, touch, mouse, and keyboard interactions.
- Triggers a callback after a configurable inactivity timeout.
- Resets the idle timer whenever user activity is detected.
- Handles app lifecycle transitions.
- Supports configurable background timeout handling.
- Allows programmatic control through `IdleLogoutController`.
- Works with lock screens, logout flows, or any custom session action.
- Does not perform navigation, authentication, logout, or storage operations internally.
- Supports synchronous and asynchronous callbacks.
- Does not write anything to device storage.

---

## Installation

Add the package to your project:

```sh
flutter pub add idle_logout
```

Or add it manually to your `pubspec.yaml`:

```yaml
dependencies:
  idle_logout: ^2.1.0
```

---

## Usage

### Basic Example

Place `IdleLogout` high in your widget tree so that it can observe activity throughout your application.

```dart
import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return IdleLogout(
      params: Params(
        timeout: const Duration(minutes: 5),
        backgroundTimeout: const Duration(seconds: 30),
        isLoggedIn: isLoggedIn,
        isLockedOut: isLockedOut,
        onLockedOut: onLockedOut,
      ),
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
      ),
    );
  }
}

Future<void> onLockedOut() async {
  // Add your custom lock or logout logic here.
  debugPrint('User locked due to inactivity');

  await navigatorKey.currentState?.pushReplacement(
    MaterialPageRoute(
      builder: (_) => const LockScreen(),
    ),
  );
}

Future<bool> isLoggedIn() async {
  // Return whether a user currently has an active session.
  return true;
}

Future<bool> isLockedOut() async {
  // Return whether the user is already locked out.
  return false;
}
```

The package does not decide how to lock out the user. It calls `onLockedOut`, and your application controls what happens next.

---

## Using the Controller

You can use `IdleLogoutController` to programmatically control idle monitoring.

```dart
final controller = IdleLogoutController();
```

Pass the controller to `IdleLogout`:

```dart
IdleLogout(
  controller: controller,
  params: Params(
    timeout: const Duration(minutes: 5),
    isLoggedIn: isLoggedIn,
    isLockedOut: isLockedOut,
    onLockedOut: onLockedOut,
  ),
  child: const MyApp(),
)
```

The controller provides the following commands:

```dart
controller.start();
controller.pause();
controller.resume();
controller.stop();
controller.reset();
```

### Controller commands

| Command    | Description                                                                |
| ---------- | -------------------------------------------------------------------------- |
| `start()`  | Starts or restarts idle monitoring.                                        |
| `pause()`  | Pauses the idle timer and records when monitoring was paused.              |
| `resume()` | Resumes monitoring and checks whether the background timeout was exceeded. |
| `stop()`   | Stops monitoring and cancels the active idle timer.                        |
| `reset()`  | Cancels the current timer and starts a new idle timeout.                   |

---

## How It Works

### User activity

The idle timer is reset when the package detects:

- Touch input
- Pointer and mouse interactions
- Keyboard key presses

When no activity occurs for the configured `timeout`, the package checks whether the user should be locked out.

`onLockedOut` is only called when:

```dart
await isLoggedIn() == true
```

and:

```dart
await isLockedOut() == false
```

If the user is already logged out or locked, `onLockedOut` is not executed.

---

## App Lifecycle Handling

When the application enters one of the following lifecycle states:

- `paused`
- `inactive`
- `hidden`

Idle monitoring is paused and the current time is recorded.

When the application returns to:

```dart
AppLifecycleState.resumed
```

the package calculates how long the application was inactive.

### Background timeout exceeded

If the time away is greater than `backgroundTimeout`, `onLockedOut` is triggered immediately.

```text
time away > backgroundTimeout
```

### Background timeout not exceeded

If the application returns before the background timeout is exceeded, a new idle timer starts.

```text
time away <= backgroundTimeout
```

The default `backgroundTimeout` is:

```dart
const Duration(seconds: 30)
```

---

## API Documentation

### `IdleLogout`

```dart
IdleLogout({
  required Widget child,
  required Params params,
  IdleLogoutController? controller,
})
```

### `Params`

```dart
Params({
  required FutureOr<bool> Function() isLoggedIn,
  required FutureOr<void> Function() onLockedOut,
  required Duration timeout,
  FutureOr<bool> Function()? isLockedOut,
  Duration? backgroundTimeout,
  bool debug = false,
})
```

---

## Parameter Details

### `child`

```dart
Widget child
```

The widget subtree to monitor for user activity.

For application-wide monitoring, place `IdleLogout` high in the widget tree:

```dart
IdleLogout(
  params: params,
  child: MaterialApp(
    home: const HomeScreen(),
  ),
)
```

Pointer and keyboard activity detected within this subtree can reset the idle timer.

---

### `controller`

```dart
IdleLogoutController? controller
```

An optional controller that allows idle monitoring to be controlled programmatically.

If no controller is provided, `IdleLogout` creates and manages its own controller.

---

### `timeout`

```dart
Duration timeout
```

The maximum amount of inactivity allowed before the idle handler runs.

The timer is reset whenever supported user activity is detected.

Example:

```dart
timeout: const Duration(minutes: 5)
```

After five minutes without activity, the package checks `isLoggedIn()` and `isLockedOut()` before executing `onLockedOut()`.

---

### `backgroundTimeout`

```dart
Duration? backgroundTimeout
```

The maximum amount of time the application can remain inactive in the background before the lock callback is triggered when the application resumes.

Example:

```dart
backgroundTimeout: const Duration(seconds: 30)
```

If the app is away for more than 30 seconds:

```text
away time > 30 seconds
```

`onLockedOut` is triggered immediately when the application resumes.

If no value is provided, the default is:

```dart
const Duration(seconds: 30)
```

A background timeout is useful when the application becomes temporarily inactive, such as when:

- The device is locked.
- The user switches applications.
- A system dialog appears.
- Another application temporarily takes focus.

---

### `isLoggedIn`

```dart
FutureOr<bool> Function() isLoggedIn
```

Determines whether a user currently has an active session.

The idle callback is only executed when this returns `true`.

Example:

```dart
isLoggedIn: () => authService.isLoggedIn,
```

If the user is logged out, the package does not execute `onLockedOut`.

---

### `isLockedOut`

```dart
FutureOr<bool> Function()? isLockedOut
```

Determines whether the user is already locked out.

This prevents `onLockedOut` from being executed when the application is already in a locked state.

Example:

```dart
isLockedOut: () => authService.isLockedOut,
```

If your application does not have a separate lock screen or lock state, you can omit this parameter.

---

### `onLockedOut`

```dart
FutureOr<void> Function() onLockedOut
```

The callback executed when the user must be locked out due to inactivity or an exceeded background timeout.

Typical responsibilities include:

- Navigating to a lock screen.
- Logging the user out.
- Clearing authentication state.
- Updating your application's lock state.
- Revoking or refreshing session tokens.

Example:

```dart
onLockedOut: () async {
  await authService.lockSession();

  navigatorKey.currentState?.pushReplacement(
    MaterialPageRoute(
      builder: (_) => const LockScreen(),
    ),
  );
},
```

The package does not perform these actions automatically.

---

### `debug`

```dart
bool debug = false
```

Enables internal debug logging when running in debug mode.

Example:

```dart
debug: true,
```

Logs include:

- Lifecycle changes.
- Timer starts and resets.
- Timer pauses and resumes.
- Background duration.
- Idle timeout handling.
- Lock callback execution.

---

## Example: Custom Logout Flow

`IdleLogout` can also be used for a traditional logout flow instead of a lock screen.

```dart
IdleLogout(
  params: Params(
    timeout: const Duration(minutes: 10),
    isLoggedIn: () => authService.isLoggedIn,
    onLockedOut: () async {
      await authService.logout();

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    },
  ),
  child: const MyApp(),
)
```

The package remains independent of your authentication implementation.

---

## Contributing

Contributions are welcome.

Before opening a pull request, please read the [Contributing Guide][contributing_link].

---

## License

Licensed under the [MIT License][license_link].

---

## Support

If you find this package useful, please consider supporting it:

- Like the [package on pub.dev](https://pub.dev/packages/idle_logout)
- Star the [GitHub repository](https://github.com/noahweasley/idle_logout)

Your support helps improve the project and keeps it actively maintained 😊

[license_link]: https://opensource.org/licenses/MIT
[contributing_link]: CONTRIBUTING.md
