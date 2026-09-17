# Alliya Kalenda

**Alliya Kalenda** est une application **local-first** pour les ingénieurs, superviseurs de chantier et chefs de projet. Elle réunit sur un seul écran vos **projets**, leur **progression**, l'**agenda** d'équipe, les **finances**, les **rapports** quotidiens et une **messagerie** de chantier — avec une synchronisation vers Supabase dès que la connexion revient.

## Design

- Identité **Alliya** : bleu marine `#0b2240` + bleu accent `#2e6fd6`, ambre pour les alertes, Material 3.
- Interface dense et professionnelle : cartes arrondies, pastilles de statut, compteurs animés.
- Tableau de bord avec héros dégradé, KPI animés et actions rapides.
- **Projets** : recherche, filtres par statut, cartes de couverture.
- **Finances** : consommation du budget, répartition par chantier, flux de paiements.
- **Personnes** : répertoire recherchable avec présence, contacts et actions rapides.
- **Messagerie** : liste filtrable par projet, recherche, bulles et pièces jointes.
- Animations fluides (révélations en cascade, compteurs, transitions de pages).

## Technologies

- Flutter (SDK `^3.12.0-210.2.beta`)
- `supabase_flutter` (adapter de synchronisation)
- `shared_preferences` (stockage local)
- `google_fonts`, `intl`, `file_picker`, `connectivity_plus`

## Lancer

```sh
flutter pub get
flutter run -d windows   # ou android
```

## Tester & analyser

```sh
flutter analyze
flutter test   # tests de widgets + tests de non-débordement (desktop & mobile)
```

## Structure

- `lib/core` : thème, tokens de couleurs, animations, formatage.
- `lib/domain` : entités et modèles.
- `lib/data` : stockage local (source de vérité) et future synchro.
- `lib/features_pages.dart` : écrans de fonctionnalités.
- `lib/messages_page.dart` : messagerie.
- `supabase/migrations` : schéma SQL (projets, paiements, messages, stockage média).
