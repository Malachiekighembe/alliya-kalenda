# Alliya Kalenda — Backend REST (`kalenda-backend/`)

API REST séparée pour Alliya Kalenda : **Node.js + Express 5 + TypeScript**.
Autonome (aucune dépendance Supabase) : PostgreSQL via **Prisma 6**, auth
**JWT** (access + refresh), mots de passe **bcrypt**, validation **Zod**.

## Stack

| Sujet | Choix |
| --- | --- |
| Serveur | Express 5 + TypeScript (ESM) |
| Base de données | PostgreSQL + Prisma 6 |
| Auth | JWT `jsonwebtoken` + `bcryptjs` |
| Validation | Zod (middleware `validate`) |
| Tests | Vitest 5 + Supertest (sans base de données) |
| Dev | `tsx watch`, build `tsc` → `dist/` |

## Routes

Toutes les routes métier sont sous `/api/v1` et exigent le header
`Authorization: Bearer <access token>` (sauf auth et santé).

| Méthode | Route | Description |
| --- | --- | --- |
| GET | `/healthz` | santé du serveur (aucune auth) |
| POST | `/api/v1/auth/register` | création de compte |
| POST | `/api/v1/auth/login` | connexion → access + refresh |
| POST | `/api/v1/auth/refresh` | rafraîchissement du token |
| GET | `/api/v1/auth/me` | profil courant |
| GET/POST | `/api/v1/projects` | liste (filtres status/q) / création |
| GET/PUT/DELETE | `/api/v1/projects/:id` | détail / mise à jour / suppression |
| GET/POST | `/api/v1/activities` | activités |
| GET/POST | `/api/v1/people` | répertoire personnes |
| GET/POST | `/api/v1/finances/payments` | encaissements |
| GET/POST | `/api/v1/finances/expenses` | dépenses |

## Démarrage

```bash
npm install
cp .env.example .env        # DATABASE_URL, JWT_ACCESS/REFRESH_SECRET, PORT
npm run db:push             # crée les tables à partir de prisma/schema.prisma
npm run db:seed             # démo : demo@alliya.cd / demo1234
npm run dev                 # http://localhost:4000
```

## Validation

```bash
npm test            # 7 tests : health, 401 sans token, 404, validation Zod
npm run typecheck   # tsc --noEmit
npm run build       # → dist/ puis npm start
npx prisma validate # schéma
```

## Structure

```
src/
  config.ts            # variables d'environnement (Zod)
  errors.ts            # AppError + codes HTTP
  app.ts               # express app (testable, sans écouter)
  index.ts             # bootstrap serveur
  lib/                 # prisma client, jwt
  middleware/          # auth, validate, error-handler
  routes/              # health, auth, projects, activities, people, finances
prisma/schema.prisma   # modèle de données (aligné sur supabase/migrations)
prisma/seed.ts         # données démo
tests/api.test.ts      # tests Vitest + Supertest
```