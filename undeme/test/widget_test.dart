import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:undeme/main.dart';

void main() {
  testWidgets('App bootstraps MaterialApp', (WidgetTester tester) async {
    await tester.pumpWidget(const UndemeApp());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
