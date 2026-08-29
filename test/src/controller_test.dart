import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_logout/idle_logout.dart';

void main() {
  group('IdleLogout Controller tests', () {
    late DateTime current;

    setUp(() {
      current = DateTime.now();
      IdleLogout.now = () => current;
    });

    tearDown(() {
      IdleLogout.now = DateTime.now;
    });

    testWidgets('controller pause pauses the timer', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
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

      controller.pause();
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('controller resume restarts timer after pause', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
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

      controller.pause();
      await tester.pump();

      current = current.add(const Duration(seconds: 1));

      controller.resume();
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('controller stop cancels the timer', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
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

      controller.stop();
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(called, isFalse);
    });

    testWidgets('controller start restarts timer after stop', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
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

      controller.stop();
      await tester.pump();

      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      expect(called, isFalse);

      controller.start();
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets('controller reset restarts the timer', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
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

      await tester.pump(const Duration(seconds: 1));

      controller.reset();
      await tester.pump();

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      expect(called, isFalse);

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isTrue);
    });

    testWidgets(
      'pointer interaction does not reset timer when paused',
      (tester) async {
        var called = false;
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        controller.pause();
        await tester.pump();

        await tester.tapAt(const Offset(100, 100));
        await tester.pump();

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets(
      'keyboard interaction does not reset timer when stopped',
      (tester) async {
        var called = false;
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        controller.stop();
        await tester.pump();

        await tester.sendKeyDownEvent(LogicalKeyboardKey.space);
        await tester.pump();

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();

        expect(called, isFalse);
      },
    );

    testWidgets('pause threshold uses strictly greater than comparison', (
      tester,
    ) async {
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

      current = current.add(const Duration(seconds: 5));

      tester.binding.handleAppLifecycleStateChanged(
        AppLifecycleState.resumed,
      );

      await tester.pump();
      await tester.pump();

      expect(called, isFalse);
    });

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
      'does not call callback after timeout when widget is disposed',
      (tester) async {
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

    testWidgets(
      'detached lifecycle state does not pause the timer',
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
          AppLifecycleState.detached,
        );

        await tester.pump(const Duration(seconds: 3));
        await tester.pump();

        expect(called, isTrue);
      },
    );
  });
}
