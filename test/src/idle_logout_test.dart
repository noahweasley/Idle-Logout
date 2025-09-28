import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:idle_logout/idle_logout.dart';

import '../utils/screen.dart';

void main() {
  group(
    'IdleLogout tests',
    () {
      testWidgets('can be instantiated and renders child', (tester) async {
        initializeScreen(tester);

        final widget = IdleLogout(
          isLoggedIn: () => true,
          isLockedOut: () => false,
          timeout: const Duration(seconds: 1),
          lockedOutAction: () async {},
          child: const Text('Hello World'),
        );

        await tester.pumpWidget(
          MaterialApp(home: widget),
        );

        expect(find.text('Hello World'), findsOneWidget);
      });

      testWidgets('calls lockedOutAction after timeout', (tester) async {
        initializeScreen(tester);

        var lockedOutCalled = false;

        final widget = IdleLogout(
          isLoggedIn: () => true,
          isLockedOut: () => false,
          timeout: const Duration(seconds: 1),
          lockedOutAction: () async {
            lockedOutCalled = true;
          },
          child: const SizedBox.shrink(),
        );

        await tester.pumpWidget(MaterialApp(home: widget));
        await tester.pumpAndSettle(const Duration(seconds: 2));

        expect(lockedOutCalled, isTrue);
      });

      testWidgets(
        'does not call lockedOutAction if user is already locked out',
        (tester) async {
          initializeScreen(tester);

          var lockedOutCalled = false;

          final widget = IdleLogout(
            isLoggedIn: () => true,
            isLockedOut: () => true,
            timeout: const Duration(seconds: 1),
            lockedOutAction: () async {
              lockedOutCalled = true;
            },
            child: const SizedBox.shrink(),
          );

          await tester.pumpWidget(MaterialApp(home: widget));
          await tester.pumpAndSettle(const Duration(seconds: 2));

          expect(lockedOutCalled, isFalse);
        },
      );
    },
  );
}
