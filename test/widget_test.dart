import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:session/main.dart';

void main() {
  testWidgets('User Form Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the initial fields are empty.
    expect(find.text(''), findsNWidgets(3)); // Three empty text fields

    // Enter user details
    await tester.enterText(find.byType(TextField).at(0), 'John Doe');
    await tester.enterText(
        find.byType(TextField).at(1), 'john.doe@example.com');
    await tester.enterText(find.byType(TextField).at(2), '25');

    // Verify that the text fields have the expected values.
    expect(find.text('John Doe'), findsOneWidget);
    expect(find.text('john.doe@example.com'), findsOneWidget);
    expect(find.text('25'), findsOneWidget);

    // Tap the 'Add User' button and trigger a frame.
    await tester.tap(find.text('Add User'));
    await tester.pump(); // Trigger a frame

    // Verify that the success message is shown.
    expect(find.text('User added to database!'), findsOneWidget);
  });
}
