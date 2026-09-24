import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alliya_kalenda/app.dart';

void main() {
  testWidgets('affiche le dashboard Alliya Kalenda', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlliyaKalendaApp());
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Progression des projets'), findsOneWidget);
    expect(find.text('Résidence Kasaï'), findsWidgets);
  });

  testWidgets('ouvre l’espace de messages depuis la navigation', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const AlliyaKalendaApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.forum_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Équipe'), findsOneWidget);
    expect(find.text('Équipe Résidence Kasaï'), findsWidgets);
  });
}
