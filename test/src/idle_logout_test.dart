import 'dart:async' show Completer;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_logout/idle_logout.dart';

void main() {
  group('IdleLogout without controller', () {
    late DateTime current;

    setUp(() {
      current = DateTime.now();
      IdleLogout.now = () => current;
    });

    tearDown(() {
      IdleLogout.now = DateTime.now;
    });

    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async {},
            ),
            child: const Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('calls callback after timeout', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('does not call callback before timeout', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('calls callback only once', (tester) async {
      var calls = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => calls++,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      await tester.pump(const Duration(seconds: 10));
      await tester.pump();

      expect(calls, 1);
    });

    testWidgets(
      'does not call callback when user is logged out',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => false,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('does not call callback when already locked', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => true,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets(
      'stops monitoring after user is found logged out',
      (tester) async {
        var checks = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async {
                  checks++;
                  return false;
                },
                isLockedOut: () async => false,
                onLockedOut: () async {},
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(checks, 1);

        await tester.tapAt(const Offset(100, 100));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(checks, 1);
      },
    );

    testWidgets(
      'stops monitoring after user is found already locked',
      (tester) async {
        var checks = 0;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async {
                  checks++;
                  return true;
                },
                onLockedOut: () async {},
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(checks, 1);

        await tester.tapAt(const Offset(100, 100));
        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(checks, 1);
      },
    );

    testWidgets('pointer interaction resets timer', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.pump(const Duration(seconds: 1));

      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('pointer interaction is ignored while paused', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );

      await tester.tapAt(const Offset(100, 100));
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('keyboard interaction resets timer', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('keyboard interaction is ignored while paused', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.space);
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets(
      'locks immediately when resumed after pause threshold',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      'does not lock when resumed before pause threshold',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 5),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 1));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'does not lock when resumed exactly at pause threshold',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 2),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'uses 30 seconds as default background timeout',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 29));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isFalse);

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 31));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      'resumes with remaining timeout after short background period',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 3),
                backgroundTimeout: const Duration(seconds: 5),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 1));
        current = current.add(const Duration(seconds: 1));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        await tester.pump(const Duration(seconds: 1));
        current = current.add(const Duration(seconds: 1));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump(const Duration(seconds: 1));
        await tester.pump();

        expect(called, isFalse);

        await tester.pump(const Duration(milliseconds: 1500));
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets('timer does not fire while app is paused', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.paused,
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets(
      'locks on resume when timeout elapsed before pausing',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 5),
                backgroundTimeout: const Duration(seconds: 30),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        current = current.add(const Duration(seconds: 5));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets('detached lifecycle does not affect timer', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.detached,
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('dispose removes observer safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async {},
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox());

      expect(find.byType(IdleLogout), findsNothing);
    });

    testWidgets('dispose cancels pending timer', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox());

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets(
      'does not call callback when disposed during async checks',
      (tester) async {
        var called = false;
        final completer = Completer<bool>();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () => completer.future,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        await tester.pumpWidget(const SizedBox());

        completer.complete(true);
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('does not lock when resumed without previous pause',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('hidden lifecycle resumes without locking before threshold',
        (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(minutes: 5),
              backgroundTimeout: const Duration(seconds: 5),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden,
      );

      current = current.add(const Duration(seconds: 1));

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      await tester.pump();
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('hidden lifecycle locks after threshold', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(minutes: 5),
              backgroundTimeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.hidden,
      );

      current = current.add(const Duration(seconds: 2));

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      await tester.pump();
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('inactive lifecycle locks after threshold', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(minutes: 5),
              backgroundTimeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.inactive,
      );

      current = current.add(const Duration(seconds: 2));

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      await tester.pump();
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets(
      'multiple pause events preserve original pause time',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 2),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 1));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.inactive,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);
      },
    );

    testWidgets(
      'resume after background timeout does not restart idle timer',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                backgroundTimeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);

        called = false;

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'resume after pause threshold does not lock logged out user',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 1),
                isLoggedIn: () async => false,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'resume after pause threshold does not lock already locked user',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(minutes: 5),
                backgroundTimeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => true,
                onLockedOut: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        current = current.add(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('logs diagnostics when debug is enabled', (tester) async {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;

      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async {},
                debug: true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(
          logs.any((log) => log.startsWith('[IdleLogout]: Initialized')),
          isTrue,
        );
        expect(
          logs.any((log) => log.startsWith('[IdleLogout]: Idle handler')),
          isTrue,
        );
      } finally {
        debugPrint = originalDebugPrint;
      }
    });

    testWidgets('does not log when debug is disabled', (tester) async {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;

      debugPrint = (message, {wrapWidth}) => logs.add(message ?? '');

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async {},
                // ignore: avoid_redundant_argument_values
                debug: false,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(logs.where((log) => log.startsWith('[IdleLogout]')), isEmpty);
      } finally {
        debugPrint = originalDebugPrint;
      }
    });
  });

  group('IdleLogout with ignorePointer', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              ignorePointer: true,
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async {},
            ),
            child: const Text('Hello'),
          ),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('does not listen for pointer events', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              ignorePointer: true,
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async {},
            ),
            child: const SizedBox(),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(IdleLogout),
          matching: find.byType(Listener),
        ),
        findsNothing,
      );
    });

    testWidgets('listens for pointer events by default', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async {},
            ),
            child: const SizedBox(),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(IdleLogout),
          matching: find.byType(Listener),
        ),
        findsOneWidget,
      );
    });

    testWidgets('pointer interaction does not reset timer', (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 2),
              ignorePointer: true,
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      await tester.tapAt(const Offset(100, 100));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isTrue);
    });
  });

  testWidgets(
    'calls callback after timeout when isLoggedIn, isLockedOut and onLockedOut is synchronous',
    (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () => true,
              isLockedOut: () => false,
              onLockedOut: () => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    },
  );

  testWidgets(
    'calls callback after timeout when isLockedOut is not provided',
    (tester) async {
      var called = false;

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              onLockedOut: () => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    },
  );
}
