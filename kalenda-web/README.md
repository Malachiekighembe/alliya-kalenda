# Alliya Kalenda — Web (Next.js)

Application web d'Alliya Kalenda, calquée sur l'app Flutter mobile/desktop
(Android + Windows) du même dépôt. Même identité visuelle (navy `#0b2240`,
accent `#2e6fd6`, ambre `#e8893c`), mêmes écrans, mêmes libellés français.

## Stack

- Next.js 16 (App Router, `src/`) + TypeScript
- Tailwind CSS 4
- `@supabase/supabase-js` + `@supabase/ssr` (optionnel, voir ci-dessous)

## Pages

| Route | Écran Flutter associé |
| --- | --- |
| `/` | Dashboard |
| `/agenda` | Agenda |
| `/projets` | Projets |
| `/messages` | Messagerie équipe |
| `/personnes` | Répertoire personnes |
| `/finances` | Finances |
| `/rapports` | Rapports de chantier |
| `/parametres` | Paramètres |

La navigation est un rail latéral à partir de 768 px (desktop) et une barre
en bas d'écran sur mobile, exactement comme le `NavigationRail` /
`NavigationBar` Flutter.

## Données

Sans configuration, l'app tourne sur `src/lib/demo-data.ts`, miroir des seeds
du store local Flutter (`lib/data/local_store.dart`). Pour brancher la vraie
base :

```bash
cp .env.example .env.local
# renseigner NEXT_PUBLIC_SUPABASE_URL et NEXT_PUBLIC_SUPABASE_ANON_KEY
```

Les migrations SQL sont dans `../supabase/migrations/` (à la racine du dépôt).

## Développement

```bash
npm install
npm run dev    # http://localhost:3000
npm run lint
npm run build
```
