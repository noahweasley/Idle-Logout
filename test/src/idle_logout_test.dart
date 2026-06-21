import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_logout/idle_logout.dart';

void main() {
  group('IdleLogout', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              lockedOutAction: () async {},
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
              lockedOutAction: () async => called = true,
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 2));

      expect(called, isTrue);
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
                lockedOutAction: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        expect(called, isFalse);
      },
    );

    testWidgets(
      'does not call callback when already locked',
      (tester) async {
        var called = false;

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => true,
                lockedOutAction: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        await tester.pump(const Duration(seconds: 2));

        expect(called, isFalse);
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
              lockedOutAction: () async => called = true,
            ),
            child: const Scaffold(
              body: SizedBox.expand(),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(seconds: 1));

      await tester.tap(find.byType(SizedBox));
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(called, isTrue);
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
              lockedOutAction: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.space);

      await tester.pump(const Duration(seconds: 1));
      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      expect(called, isTrue);
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
                pauseThreshold: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                lockedOutAction: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        // trigger pause
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        // IMPORTANT: ensure real time passes (this fixes your failure)
        await Future.delayed(const Duration(seconds: 2));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

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
                pauseThreshold: const Duration(seconds: 5),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                lockedOutAction: () async => called = true,
              ),
              child: const SizedBox(),
            ),
          ),
        );

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.paused,
        );

        await Future.delayed(const Duration(seconds: 1));

        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );

        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('dispose removes observer safely', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              lockedOutAction: () async {},
            ),
            child: const SizedBox(),
          ),
        ),
      );

      await tester.pumpWidget(const SizedBox());

      expect(find.byType(IdleLogout), findsNothing);
    });
  });
}
