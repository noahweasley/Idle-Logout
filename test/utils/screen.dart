import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void initializeScreen(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
}
