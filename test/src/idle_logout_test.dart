import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_logout/idle_logout.dart';

void main() {
  group('IdleLogout', () {
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

    testWidgets('does not call callback when user is logged out', (tester) async {
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
    });

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

    testWidgets('locks immediately when resumed after pause threshold', (tester) async {
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
    });

    testWidgets('does not lock when resumed before pause threshold', (tester) async {
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

    testWidgets('does not lock when resumed without previous pause', (tester) async {
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

    testWidgets('hidden lifecycle resumes without locking before threshold', (tester) async {
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

    testWidgets('multiple pause events preserve original pause time', (tester) async {
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
    });
  });

  testWidgets('calls callback after timeout when isLoggedIn, isLockedOut and onLockedOut is synchronous', (tester) async {
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
  });

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
