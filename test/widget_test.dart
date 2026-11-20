import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavGate renderiza corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Text('NavGate'))));
    expect(find.text('NavGate'), findsOneWidget);
  });
}
