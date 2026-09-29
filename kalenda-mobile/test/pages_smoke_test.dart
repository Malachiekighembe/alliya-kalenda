import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:alliya_kalenda/app.dart';
import 'package:alliya_kalenda/core/api_client.dart';
import 'package:alliya_kalenda/core/project_cover.dart';
import 'package:alliya_kalenda/data/local_store.dart';
import 'package:alliya_kalenda/domain/models.dart';

/// Payload projet tel que renvoye par le backend : `Decimal` serialise en
/// chaine, enums anglais. Les tests verifient donc aussi les mappers.
const projectA = '11111111-1111-1111-1111-111111111111';
const projectB = '22222222-2222-2222-2222-222222222222';

const _projects = [
  {
    'id': projectA,
    'name': 'Résidence Kasaï',
    'reference': 'AK-2026-001',
    'clientName': 'Groupe Mwamba',
    'location': 'Kasaï, Kinshasa',
    'description': '',
    'startDate': null,
    'plannedEndDate': '2026-12-01T00:00:00.000Z',
    'actualEndDate': null,
    'contractAmount': '145000.00',
    'status': 'active',
    'progress': '68.00',
    'notes': '',
  },
  {
    'id': projectB,
    'name': 'Atelier Kalenda',
    'reference': 'AK-2026-002',
    'clientName': 'Kalenda SARL',
    'location': 'Lemba, Kinshasa',
    'description': '',
    'startDate': null,
    'plannedEndDate': '2026-11-01T00:00:00.000Z',
    'actualEndDate': null,
    'contractAmount': '76500.00',
    'status': 'active',
    'progress': '42.00',
    'notes': '',
  },
];

const _people = [
  {
    'id': 'p1',
    'fullName': 'Jean Kalala',
    'phone': '+243 81 000 000',
    'jobTitle': 'Chef de chantier',
    'address': '',
    'notes': '',
  },
  {
    'id': 'p2',
    'fullName': 'Mado Tshibanda',
    'phone': '',
    'jobTitle': 'Génie civil',
    'address': '',
    'notes': '',
  },
];

const _conversations = [
  {
    'id': 'c1',
    'title': 'Équipe Résidence Kasaï',
    'recipientLabel': 'Chef de chantier',
    'project': {
      'id': projectA,
      'name': 'Résidence Kasaï',
      'reference': 'AK-2026-001',
    },
    'projectId': projectA,
    'createdAt': '2026-09-20T08:00:00.000Z',
    'updatedAt': '2026-09-27T09:00:00.000Z',
    'messageCount': 2,
    'unread': 1,
    'lastMessage': {
      'id': 'm1',
      'body': 'Livraison réceptionnée.',
      'sentAt': '2026-09-27T09:00:00.000Z',
      'mine': false,
    },
  },
  {
    'id': 'c2',
    'title': 'Direction travaux',
    'recipientLabel': 'Groupe interne',
    'project': null,
    'projectId': null,
    'createdAt': '2026-09-20T08:00:00.000Z',
    'updatedAt': '2026-09-26T09:00:00.000Z',
    'messageCount': 1,
    'unread': 0,
    'lastMessage': null,
  },
];

/// URL injectee dans les tests : le --dart-define n'est pas disponible ici.
const _apiUrl = 'https://api.test.local';

/// Reponses du backend simule, indexees par chemin de requete.
Map<String, Object> _routes() => {
  '/api/v1/projects': _projects,
  '/api/v1/people': _people,
  '/api/v1/conversations': _conversations,
  '/api/v1/activities': [
    {
      'id': 'a1',
      'title': 'Contrôle ferraillage',
      'projectId': projectA,
      'description': '',
      'status': 'in_progress',
      'priority': 'urgent',
      'activityDate': '2026-09-27T08:00:00.000Z',
      'notes': '',
      'project': {'id': projectA, 'name': 'Résidence Kasaï'},
    },
  ],
  '/api/v1/finances/payments': [
    {
      'id': 'pay1',
      'projectId': projectA,
      'amount': '18500.00',
      'paymentDate': '2026-09-12',
      'method': 'Virement',
      'notes': '',
    },
  ],
  '/api/v1/reports': [
    {
      'id': 'r1',
      'projectId': projectA,
      'title': 'Rapport journalier',
      'body': 'Aucun blocage critique.',
      'reportDate': '2026-09-20T00:00:00.000Z',
      'project': {
        'id': projectA,
        'name': 'Résidence Kasaï',
        'reference': 'AK-2026-001',
      },
    },
  ],
  '/api/v1/finances/summary': {
    'received': 18500.0,
    'spent': 12450.0,
    'balance': 6050.0,
    'paymentsCount': 1,
    'expensesCount': 3,
  },
  '/api/v1/auth/me': {
    'id': 'u1',
    'email': 'test@alliyakalenda.cd',
    'createdAt': '2026-09-01T00:00:00.000Z',
    'profile': {
      'fullName': 'Test Utilisateur',
      'companyName': 'Kalenda',
      'phone': '',
      'currency': 'USD',
      'dateFormat': 'dd/MM/yyyy',
      'darkMode': false,
    },
  },
};

/// Client HTTP simule servant les [routes] et renvoyant une vraie enveloppe
/// d'erreur du backend pour tout le reste.
http.Client fakeClient([Map<String, Object>? routes]) {
  final table = routes ?? _routes();
  return MockClient((request) async {
    final path = request.url.path;
    final body = table[path];
    if (body == null) {
      return http.Response(
        jsonEncode({
          'error': {'message': 'Route introuvable : $path', 'details': null},
        }),
        404,
        headers: {'content-type': 'application/json'},
      );
    }
    return http.Response(
      jsonEncode(body),
      200,
      headers: {'content-type': 'application/json'},
    );
  });
}

/// Demarre l'application avec une session deja ouverte sur le backend simule.
Future<void> _pumpSignedInApp(
  WidgetTester tester,
  Size logicalSize, {
  Map<String, Object>? routes,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = logicalSize;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues({
    'kalenda.accessToken': 'access-token',
    'kalenda.refreshToken': 'refresh-token',
  });
  await SharedPreferences.getInstance();
  await tester.pumpWidget(
    AlliyaKalendaApp(
      storeFactory: (p) => LocalStore(
        p,
        api: ApiClient(client: fakeClient(routes), baseUrl: _apiUrl),
      ),
    ),
  );
  // Le store restaure la session de facon asynchrone : on laisse les
  // reponses HTTP se resoudre avant d'observer l'interface.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

/// Demarre l'application sans session : la page de connexion doit s'afficher.
Future<void> _pumpAnonymousApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await tester.pumpWidget(
    AlliyaKalendaApp(
      storeFactory: (p) => LocalStore(
        p,
        api: ApiClient(client: fakeClient(), baseUrl: _apiUrl),
      ),
    ),
  );
  // Le store restaure la session de facon asynchrone : on laisse les
  // reponses HTTP se resoudre avant d'observer l'interface.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sans session, l'
      'écran de connexion occupe tout l'
      'écran', (tester) async {
    await _pumpAnonymousApp(tester);

    expect(find.text('Alliya Kalenda'), findsOneWidget);
    expect(find.text('Se connecter'), findsOneWidget);
    // Aucune donnée métier ne doit fuiter avant authentification.
    expect(find.text('Résidence Kasaï'), findsNothing);
    expect(find.text('Jean Kalala'), findsNothing);
  });

  testWidgets('aucun débordement sur desktop (rail de navigation)', (
    tester,
  ) async {
    await _pumpSignedInApp(tester, const Size(1440, 900));
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
    await _pumpSignedInApp(tester, const Size(360, 720));
    final navBar = find.byType(NavigationBar);
    expect(navBar, findsOneWidget);

    for (final icon in <IconData>[
      Icons.apartment_outlined,
      Icons.forum_outlined,
      Icons.grid_view_rounded,
    ]) {
      await tester.tap(
        find.descendant(of: navBar, matching: find.byIcon(icon)).first,
      );
      await tester.pumpAndSettle();
    }
  });

  testWidgets('le menu « Plus » liste les espaces secondaires', (tester) async {
    await _pumpSignedInApp(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();

    expect(find.text('Autres espaces'), findsOneWidget);
    expect(find.text('Personnes'), findsOneWidget);

    await tester.tap(find.text('Finances'));
    await tester.pumpAndSettle();
    expect(find.text('Suivi de trésorerie par chantier'), findsOneWidget);
  });

  testWidgets('le dashboard affiche les projets renvoyés par l'
      'API', (tester) async {
    await _pumpSignedInApp(tester, const Size(1200, 900));

    // Les projets viennent du backend, avec leurs noms reels.
    expect(find.text('Résidence Kasaï'), findsWidgets);
    expect(find.text('Atelier Kalenda'), findsWidgets);

    expect(find.text('Paiements récents'), findsOneWidget);
  });

  testWidgets('la liste des projets expose une vraie photo de chantier', (
    tester,
  ) async {
    await _pumpSignedInApp(tester, const Size(1200, 900));

    await tester.tap(find.byIcon(Icons.apartment).first);
    await tester.pumpAndSettle();

    final covers = tester.widgetList<ProjectCover>(find.byType(ProjectCover));
    expect(covers, isNotEmpty);
    for (final cover in covers) {
      expect(cover.source, isNotEmpty);
      expect(kProjectCovers.contains(cover.source), isTrue);
    }
  });

  testWidgets('le répertoire filtre les personnes venues de l'
      'API', (tester) async {
    await _pumpSignedInApp(tester, const Size(390, 844));
    await tester.tap(find.byIcon(Icons.more_horiz_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Personnes'));
    await tester.pumpAndSettle();

    expect(find.text('Jean Kalala'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Mado');
    await tester.pumpAndSettle();

    expect(find.text('Mado Tshibanda'), findsOneWidget);
    expect(find.text('Jean Kalala'), findsNothing);
  });

  testWidgets('la messagerie liste les discussions de l'
      'API', (tester) async {
    await _pumpSignedInApp(tester, const Size(1200, 900));
    await tester.tap(find.byIcon(Icons.forum_outlined).first);
    await tester.pumpAndSettle();

    expect(find.text('Conversations'), findsOneWidget);
    expect(find.text('Équipe Résidence Kasaï'), findsWidgets);

    await tester.enterText(find.byType(TextField).first, 'Direction');
    await tester.pumpAndSettle();
    // Le titre de l'en-tete reste affiche : on verifie la liste filtree.
    expect(find.text('Direction travaux'), findsWidgets);
  });

  testWidgets('l'
      'agenda et les rapports lisent les ressources de l'
      'API', (tester) async {
    await _pumpSignedInApp(tester, const Size(1200, 900));

    await tester.tap(find.byIcon(Icons.calendar_month).first);
    await tester.pumpAndSettle();
    expect(find.text('Contrôle ferraillage'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.description).first);
    await tester.pumpAndSettle();
    expect(find.text('Aucun blocage critique.'), findsOneWidget);
  });

  // ---------------------------------------------------------------- Modeles

  test('les Decimal serialises en chaine sont reconvertis en nombres', () {
    final project = Project.fromApi({
      'id': projectA,
      'name': 'Résidence Kasaï',
      'reference': 'AK-2026-001',
      'clientName': 'Groupe Mwamba',
      'location': 'Kasaï',
      'contractAmount': '145000.00',
      'progress': '68.00',
      'status': 'active',
      'plannedEndDate': '2026-12-01T00:00:00.000Z',
    }, imageUrl: '/covers/cover-01.jpg');

    expect(project.contractAmount, 145000.0);
    expect(project.progress, 68.0);
    expect(project.status, ProjectStatus.active);
    expect(project.client, 'Groupe Mwamba');
  });

  test('les enums anglais du backend deviennent des libelles francais', () {
    final activity = Activity.fromApi({
      'title': 'Controle ferraillage',
      'status': 'in_progress',
      'priority': 'urgent',
      'activityDate': '2026-09-27T08:30:00.000Z',
      'project': {'name': 'Résidence Kasaï'},
    });

    expect(activity.status, 'En cours');
    expect(activity.priority, 'Urgente');
    expect(activity.project, 'Résidence Kasaï');
    expect(activity.time, isNot('--:--'));
  });

  test('une personne sans chantier est marquee « non affectee »', () {
    final person = Person.fromApi({
      'id': 'x1',
      'fullName': 'Jean Kalala',
      'jobTitle': 'Chef de chantier',
      'phone': '',
    });

    expect(person.onSite, isFalse);
    expect(person.project, 'Non affecté');
  });
}
