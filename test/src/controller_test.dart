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

    testWidgets('controller start is ignored while paused', (tester) async {
      var called = false;
      final controller = IdleLogoutController();

      await tester.pumpWidget(
        MaterialApp(
          home: IdleLogout(
            controller: controller,
            params: Params(
              timeout: const Duration(seconds: 1),
              isLoggedIn: () async => true,
              isLockedOut: () async => false,
              onLockedOut: () async => called = true,
            ),
            child: const SizedBox.expand(),
          ),
        ),
      );

      controller.pause();
      controller.start();
      await tester.pump();

      await tester.pump(const Duration(seconds: 2));
      await tester.pump();

      expect(called, isFalse);
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
      'controller resume locks when paused longer than background timeout',
      (tester) async {
        var called = false;
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        controller.pause();

        current = current.add(const Duration(seconds: 2));

        controller.resume();

        await tester.pump();
        await tester.pump();

        expect(called, isTrue);
      },
    );

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
      'pointer interaction does not reset timer when stopped',
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

        controller.stop();
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

    testWidgets(
      'controller pause on an already paused timer is safe',
      (tester) async {
        var called = false;
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
              params: Params(
                timeout: const Duration(seconds: 1),
                isLoggedIn: () async => true,
                isLockedOut: () async => false,
                onLockedOut: () async => called = true,
                debug: true,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        );

        controller.pause();
        controller.pause();
        await tester.pump();

        await tester.pump(const Duration(seconds: 2));
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(called, isFalse);
      },
    );

    testWidgets(
      'does not dispose externally provided controller',
      (tester) async {
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        expect(() => controller.start(), returnsNormally);

        controller.dispose();
      },
    );

    testWidgets(
      'controller can be reused by a new IdleLogout after dispose',
      (tester) async {
        var called = false;
        final controller = IdleLogoutController();

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        await tester.pumpWidget(
          MaterialApp(
            home: IdleLogout(
              controller: controller,
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

        await tester.pumpWidget(const SizedBox());

        controller.dispose();
      },
    );
  });
}
