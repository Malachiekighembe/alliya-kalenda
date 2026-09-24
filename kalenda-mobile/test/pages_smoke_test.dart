import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alliya_kalenda/app.dart';
import 'package:alliya_kalenda/core/project_cover.dart';

/// Boots the app at a fixed logical size so every layout branch (mobile
/// navigation bar vs. desktop rail) can be exercised without overflow.
Future<void> _pumpApp(WidgetTester tester, Size logicalSize) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(const AlliyaKalendaApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('aucun débordement sur desktop (rail de navigation)', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1440, 900));
    final rail = find.byType(NavigationRail);
    expect(rail, findsOneWidget);

    for (final icon in <IconData>[
      Icons.calendar_month,
      Icons.apartment,
      Icons.forum_outlined,
      Icons.groups,
      Icons.account_balance_wallet,
      Icons.description,
      Icons.settings,
    ]) {
      final destination = find
          .descendant(of: rail, matching: find.byIcon(icon))
          .first;
      await tester.ensureVisible(destination);
      await tester.pumpAndSettle();
      await tester.tap(destination);
      await tester.pumpAndSettle();
    }
  });

  testWidgets('aucun débordement sur mobile étroit', (tester) async {
    await _pumpApp(tester, const Size(360, 720));
    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);

    for (final icon in <IconData>[
      Icons.apartment,
      Icons.forum_outlined,
      Icons.grid_view,
    ]) {
      await tester.tap(
        find.descendant(of: navBar, matching: find.byIcon(icon)).first,
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('le menu « Plus » liste les espaces secondaires', (tester) async {
    await _pumpApp(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();

    expect(find.text('Autres espaces'), findsOneWidget);
    expect(find.text('Personnes'), findsOneWidget);

    await tester.tap(find.text('Finances'));
    await tester.pumpAndSettle();
    expect(find.text('Suivi de trésorerie par chantier'), findsOneWidget);
  });

  testWidgets('la recherche de personnes filtre le répertoire', (tester) async {
    await _pumpApp(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personnes'));
    await tester.pumpAndSettle();

    expect(find.text('Jean Kalala'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Mado');
    await tester.pumpAndSettle();

    expect(find.text('Mado Tshibanda'), findsOneWidget);
    expect(find.text('Jean Kalala'), findsNothing);
  });

  testWidgets('la recherche de conversations filtre la messagerie', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1200, 900));
    await tester.tap(find.byIcon(Icons.forum_outlined).first);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'Kalenda');
    await tester.pumpAndSettle();

    expect(find.text('Atelier Kalenda'), findsWidgets);
    expect(find.text('Direction travaux'), findsNothing);
  });

  testWidgets('le dashboard et les cartes projet affichent une vraie photo', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1200, 900));

    // Dashboard hero + lignes « Progression des projets ».
    expect(find.byType(ProjectCover), findsWidgets);

    // Page Projets : chaque carte embarque une photo de chantier.
    await tester.tap(find.byIcon(Icons.apartment).first);
    await tester.pumpAndSettle();

    final covers = tester.widgetList<ProjectCover>(find.byType(ProjectCover));
    expect(covers, isNotEmpty);
    for (final cover in covers) {
      expect(cover.source, isNotEmpty);
      expect(
        cover.source.startsWith('http') ||
            kProjectCovers.contains(cover.source),
        isTrue,
        reason:
            'Chaque projet doit pointer vers une photo réelle, pas un aplat.',
      );
    }

    // L'image est effectivement rendue (asset bundled, lisible hors ligne).
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('les vignettes du dashboard réutilisent la photo du chantier', (
    tester,
  ) async {
    await _pumpApp(tester, const Size(1200, 900));

    final covers = tester
        .widgetList<ProjectCover>(find.byType(ProjectCover))
        .toList();
    expect(covers.length, greaterThanOrEqualTo(2));
    expect(
      covers.every((cover) => kProjectCovers.contains(cover.source)),
      isTrue,
    );
  });
}
