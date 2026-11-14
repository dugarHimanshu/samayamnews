# Samayam News — Backend

Node.js + Express 5 + TypeScript API for the Samayam News app. Supabase provides Postgres, Auth and
Storage; this service is the only thing that reads or writes application data.

Design: [`docs/backend-architecture.md`](docs/backend-architecture.md)

## Stack

| | |
|---|---|
| HTTP | Express 5, helmet, cors, express-rate-limit, pino logs with request ids |
| Validation | Zod |
| Database | Supabase Postgres via Drizzle ORM + postgres.js (tables live in the private `app` schema) |
| Auth | Supabase Auth JWTs, verified offline (JWKS or HS256 secret); roles from `app.profiles` |
| Jobs | pg-boss (queue stored in Postgres) — image processing, account deletion, push |
| Images | sharp → 320/640/1080 px WebP, all EXIF/GPS stripped |
| Tests | Vitest + supertest against a local Supabase |

## Local development

Requirements: Node 22+, Docker Desktop.

```bash
cd backend
npm install
npx supabase start            # local Postgres + Auth + Storage in Docker (first run downloads images)
npx supabase status -o env    # copy DB_URL / API_URL / SERVICE_ROLE_KEY / JWT_SECRET into .env
cp .env.example .env          # then fill in the values above and TEST_USER_PASSWORD

npm run db:migrate            # create the app schema
npm run setup:storage         # create the raw (private) and media (public) buckets
npm run seed:reference        # categories + default runtime config
npm run seed:locations        # LGD districts, mandals, villages for Telangana + Andhra Pradesh
npm run seed:users            # admin@ / editor@ / employee@ / freelancer@ / reader@samayam.test
npm run seed:demo             # demo articles, ads, magazines (remove with: npm run seed:demo -- --reset)

npm run dev                   # API on http://localhost:4000 (jobs run in-process when WORKER_INLINE=true)
npm test
```

Supabase Studio (database browser) runs at http://127.0.0.1:54323.

## API overview (`/v1`)

| Area | Endpoints |
|---|---|
| Public (CDN-cached) | `GET /feed?district=`, `/feed/head`, `/articles?district=&mandal=&category=`, `/articles/:id`, `/search?q=`, `/categories`, `/locations?parent=&level=`, `/magazines`, `/magazines/:id`, `/config` |
| Reader | `GET/PATCH/DELETE /me`, `GET /me/bookmarks`, `PUT/DELETE /me/bookmarks/:articleId`, `PUT/DELETE /me/likes/:articleId`, `GET /me/state?ids=`, `POST /devices`, `POST /events` |
| Contributor | `POST /uploads` → upload to signed URL → `POST /uploads/:id/complete`, `POST /submissions`, `GET /me/submissions`, `GET /me/submission-quota` |
| Editor | `GET /editor/queue`, `/editor/stats`, `POST /editor/submissions/:id/{claim,heartbeat,release,publish,reject}`, `PATCH /editor/submissions/:id`, `PATCH /editor/articles/:id`, `POST /editor/articles/:id/{unpublish,republish}` |
| Admin | `GET /admin/stats`, `GET/PATCH /admin/users`, CRUD `/admin/ads`, `/admin/magazines`, `GET /admin/ads/:id/report`, `GET/PUT /admin/config/:key` |

All errors look like `{ "error": { "code", "message", "requestId" } }`. Every response carries an
`x-request-id` header that matches the server log line.

### Feed rule
If `district` is given, that district's articles from the last 48 hours come first (newest first), then
all other articles newest-first. Pagination uses opaque keyset cursors, so every page is equally fast and
nothing repeats. Ads (every 5 articles) and magazines are mixed in by the server; frequencies are in
`app_config.feed` and can be changed without a release.

## Demo deployment (Render free)

`render.yaml` deploys the API (with jobs in-process) from the `backend/` folder. Set `DATABASE_URL`,
`SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY` and `CORS_ORIGINS` in the Render dashboard, pointing at a
Supabase project. The free plan sleeps when idle — open the app a minute before a demo.

## Running the Flutter app against this API

The app talks to Supabase only for sign-in; everything else goes to `API_BASE_URL`. Point it at the
local stack with `--dart-define`s (the anon/publishable key is printed by `npx supabase status`):

```bash
flutter run \
  --dart-define=API_BASE_URL=http://localhost:4000 \
  --dart-define=SUPABASE_URL=http://127.0.0.1:54321 \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<local anon key>
```

On the Android emulator use `http://10.0.2.2:4000` / `http://10.0.2.2:54321` instead of localhost.
For a web build, add its origin (e.g. `http://localhost:3000`) to `CORS_ORIGINS` in `.env`.
