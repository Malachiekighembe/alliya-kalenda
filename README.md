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

## Plateformes

Cibles actives : **Android** (mobile) et **Windows** (desktop) pour Flutter,
une application **web Next.js** dans le sous-dossier `web/`, et un **backend
REST séparé** dans le sous-dossier `api/` (voir ci-dessous). Aucun
`flutter build web` ni config Vercel Flutter ici.

## Lancer

```sh
flutter pub get
flutter run -d windows   # ou : flutter run -d android
```

## Livrer (release locale)

```sh
flutter build apk --release
# -> build/app/outputs/flutter-apk/app-release.apk

flutter build windows --release
# -> build/windows/x64/runner/Release/AlliyaKalenda.exe (+ dossier d'accompagnement)
```

Copiez ensuite les artefacts vers `release/` (ignoré par git) pour distribution manuelle.

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
- `supabase/migrations` : schéma SQL historique (référence du modèle de données).
- `web/` : app web **Next.js 16** (voir `web/README.md`).
- `api/` : **backend REST Node.js + Express + TypeScript** (voir ci-dessous).

## Backend REST (`api/`)

Backend séparé, autonome (ni Supabase Auth ni Supabase JS) :

- **Stack** : Node.js + Express 5 + TypeScript, validation **Zod**, auth
  **JWT** (access + refresh), mots de passe **bcrypt**, persistance
  **PostgreSQL via Prisma 6**, tests **Vitest + Supertest**.
- **Routes** : `POST /api/v1/auth/register|login|refresh`, `GET /api/v1/auth/me`,
  `GET|POST /api/v1/projects` (+ `/:id`), `activities`, `people`,
  `finances/payments`, `finances/expenses`, `GET /healthz`.

```sh
cd api
npm install
cp .env.example .env        # renseigner DATABASE_URL + JWT secrets
npm run db:push             # crée les tables (schéma Prisma)
npm run db:seed             # utilisateur démo demo@alliya.cd / demo1234
npm run dev                 # http://localhost:4000

npm test                    # 7 tests (health, 401, 404, validation…)
npm run typecheck
npm run build && npm start  # dist/ en production
```
