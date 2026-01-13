<p align="center" style="font-size: 4rem;">
  💤
</p>
<h1 align="center">Idle Logout</h1>

<p align="center">
  <img src="https://img.shields.io/badge/Dart-≥3.0-blue?logo=dart&logoColor=white" alt="Minimum Dart Version" />
  <img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20macOS%20%7C%20Windows%20%7C%20Linux-009688?logo=flutter&logoColor=white&color=009688" alt="Platform" />
  <img src="https://img.shields.io/badge/Style-Very%20Good%20CLI-purple?logo=very-good&logoColor=white" alt="Very Good CLI" />
</p>

<p align="center">
A Flutter package for handling automatic user logout after a period of inactivity. Ideal for apps where session security and compliance are important (e.g., banking, healthcare, enterprise apps).
</p>

<br/>

<p align="start">
  <img src="demo/demo.gif" alt="Idle Logout Demo" width="400" />
</p>

---

## Features

* Detects user inactivity.
* Logs out automatically after a configurable timeout.
* Resets the timer on user activity.
* Simple and flexible API.

---

## Installation

Add to your project:

```sh
flutter pub add idle_logout
```

Or manually add to your `pubspec.yaml`:

```yaml
dependencies:
  idle_logout: ^0.1.4
```

---

## Usage

### Basic Example

```dart
import 'package:flutter/material.dart';
import 'package:idle_logout/idle_logout.dart';

import '../../screens/home_screen.dart';
import 'screens/lock_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return IdleLogout(
      pauseThreshold: const Duration(seconds: 15),
      timeout: const Duration(seconds: 10),
      isLoggedIn: () => true,
      isLockedOut: () => false,
      lockedOutAction: () async {
        debugPrint('User logged out due to inactivity');

        navigatorKey.currentState?.pushReplacement(
          MaterialPageRoute<void>(
            builder: (BuildContext context) => const LockScreen(),
          ),
        );
      },
      child: MaterialApp(
        navigatorKey: navigatorKey,
        home: const HomeScreen(),
      ),
    );
  }
}
```

---

## API Documentation

### Constructor

```dart
IdleLogout({
  required Widget child,
  required bool Function() isLoggedIn,
  required bool Function() isLockedOut,
  required Future<void> Function() lockedOutAction,
  required Duration timeout,
  Duration? pauseThreshold,
})
```

---

### Parameters

#### `child`

```dart
Widget child
```

The widget subtree to monitor for user activity.

This is typically your `MaterialApp`, `CupertinoApp`, or a top‑level page. All pointer and keyboard events within this subtree reset the idle timer.

---

#### `timeout`

```dart
Duration timeout
```

The duration of inactivity allowed before the user is considered idle.

* The timer resets on every user interaction (touch, mouse, keyboard).
* When this duration elapses with no interaction, the idle handler is triggered.

---

#### `pauseThreshold`

```dart
Duration? pauseThreshold
```

The maximum amount of time the app may remain in the background before the user is automatically logged out on resume.

* If the app resumes after being paused longer than this duration, `lockedOutAction` is executed immediately.
* If not provided, this defaults to **30 seconds**.

This helps protect sessions when the app is backgrounded or the device is locked.

---

#### `isLoggedIn`

```dart
bool Function() isLoggedIn
```

Determines whether idle monitoring should be active.

* If this returns `false`, idle detection is disabled.
* Useful for login, onboarding, or public routes.

This callback should be synchronous and inexpensive.

---

#### `isLockedOut`

```dart
bool Function() isLockedOut
```

Indicates whether the user is already logged out or locked.

* Prevents multiple executions of `lockedOutAction`.
* Avoids duplicate navigation or logout calls.

---

#### `lockedOutAction`

```dart
Future<void> Function() lockedOutAction
```

The callback executed when the user must be logged out due to inactivity.

Typical responsibilities include:

* Clearing authentication state
* Revoking tokens
* Navigating to a login or lock screen
* Displaying a session‑expired message

This action is executed only if:

* `isLoggedIn()` returns `true`
* `isLockedOut()` returns `false`

---

## Testing

This package is set up with [Very Good Analysis][very_good_analysis_link] and [Very Good Workflows][very_good_workflows_link].

Run tests with:

```sh
very_good test --coverage
```

Generate and view coverage:

```sh
genhtml coverage/lcov.info -o coverage/
open coverage/index.html
```

---

## License

Licensed under the [MIT License][license_link].

---

[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
