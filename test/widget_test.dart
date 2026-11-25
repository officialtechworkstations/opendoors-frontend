import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders the OpenDoors app shell', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text('OpenDoors')),
      ),
    );

    expect(find.text('OpenDoors'), findsOneWidget);
  });
}
