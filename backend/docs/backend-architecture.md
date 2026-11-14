# Samayam News — Backend Architecture (v1)

_Status: draft for review · 2026-11-14_

## 1. Goals and confirmed scope

| Item | Decision |
|---|---|
| Scale target | 10,000 concurrent users with breaking-news spikes. Launch at 100–250 concurrent, then 1.5k–4k after 2 months |
| Publishing volume | 50–100 articles/day at launch, 300–500/day after 2 months |
| Regions | Telangana (33 districts) and Andhra Pradesh (28 districts). Full district → mandal → village hierarchy at launch |
| Content language | Any language (Telugu, English, Hindi, …); each article stores its language |
| Feed | Everyone sees all news. If the app sends a district, that district's news from the **last 48 hours** comes first, then all news newest-first |
| Auth (now) | Email + password, test accounts only (one per role), created by a seed script |
| Ads | Managed by the in-house team, no targeting yet. Impressions and clicks are counted |
| Data residency | India only (Google Cloud Run Mumbai `asia-south1` and Supabase Mumbai `ap-south-1`) |
| Hosting | **Decided at launch.** Develop locally in Docker now. At launch, deploy the same containers to either **AWS (ECS Fargate, Mumbai)** or **Google Cloud Run (Mumbai)**. Both work; the code is identical |
| Stack | Node.js + Express + TypeScript. Supabase stays as the database, auth and storage (option A) |
| **Out of scope for v1** | Audio news, phone OTP, reporter payments, ad targeting, automatic translation |

## 2. Architecture

```
                 Flutter app (Android / iOS / Web)
                   │ (1) login only            │ (2) everything else (HTTPS + JWT)
                   ▼                           ▼
          Supabase Auth (Mumbai)        Cloudflare  (CDN · WAF · rate limit · DDoS)
                                               │  caches public GETs (feed, article, locations…)
                                               ▼
                              ┌────────────────┴───────────────┐
                              ▼                                ▼
                    API service (Express, TS)        Worker service (pg-boss, TS)
                    Cloud Run, Mumbai                Cloud Run, Mumbai
                    min 1 → max 10 instances         1 always-on instance
                              │                                │
                              ▼                                ▼
                 Supabase Postgres (Mumbai, via Supavisor)   Supabase Storage    Firebase FCM
                 data · job queue (pg-boss) · counters       images, PDFs        push to topics
```

**No Redis at launch.** The job queue runs inside Postgres (pg-boss), caching is handled by Cloudflare plus a small in-memory cache in each API instance, and counters are buffered in memory and flushed every 30 seconds. That is one fewer service to run and pay for. Redis (Upstash, Mumbai region) can be added later as a drop-in if load requires it.

**Rules:**
- **The app talks to Supabase directly only for auth** (sign-in and token refresh) and for **uploading a file to a signed URL issued by the API**. Every database read and write goes through the API.
- **The database is locked down.** The `anon` and `authenticated` roles get no grants on application tables, and RLS is enabled with no client policies. Even if someone extracts the publishable key from the app, it can't read or write any table.
- **Public endpoints return the same answer for every user**, so Cloudflare can cache them. Per-user state (likes, bookmarks) comes from separate `/me/*` endpoints.
- **No Kafka, no nginx, no Redis.** 500 articles a day is about one write every 3 minutes. pg-boss (a job queue stored in Postgres) handles background jobs. Cloudflare plus Cloud Run's built-in HTTPS load balancing cover TLS, caching and rate limiting.

### Tech stack

| Concern | Choice |
|---|---|
| Runtime | Node.js 22 LTS, TypeScript (strict) |
| HTTP framework | Express 5 (+ `express-rate-limit`, `cors`, `helmet`) |
| Validation and API docs | Zod schemas → OpenAPI (`@asteasolutions/zod-to-openapi`) |
| Database access | Drizzle ORM + `postgres.js` through Supavisor (transaction mode, `prepare: false`) |
| Migrations | Drizzle Kit, run in CI before each deploy |
| Queue | pg-boss (in Postgres) |
| In-process cache | `lru-cache` (hot feed pages, config, categories) |
| Images | `sharp` (resize, WebP, **strip EXIF/GPS**) |
| Push | `firebase-admin` (FCM topics) |
| Auth verification | `jose`: verifies Supabase JWTs offline against the project's JWKS |
| Logging and errors | `pino` → Google Cloud Logging, Sentry (with personal data scrubbed) |
| Tests | Vitest + Testcontainers (real Postgres), k6 for load |
| CI/CD | GitHub Actions → Docker → Artifact Registry → Cloud Run |

Repository: the existing `dugarHimanshu/samayamnews` repo, in a new `backend/` folder beside the Flutter app, with `src/api`, `src/worker`, `src/db` (schema and migrations), `scripts/` (seed, LGD import) and `load-tests/`. Work happens on a `backend` branch and is merged by pull request.

## 3. Data model (Postgres)

```
locations         id (LGD code, PK) · level (state|district|mandal|town|village) · parent_id
                  · state_id · district_id · mandal_id · name_en · name_te · slug · is_active
profiles          id (= auth.users.id) · role (reader|freelancer|employee|editor|admin)
                  · full_name · language · home_district_id · created_at · deleted_at
categories        id · slug · name_en · name_te · name_hi · sort_order · is_active
media             id · owner_id · kind (image|pdf) · raw_key · variants jsonb · width · height
                  · status (pending|ready|failed) · created_at
submissions       id · submitter_id · title · summary · body · language · category_id
                  · state_id · district_id · mandal_id · village_id · cover_media_id
                  · author_name · source · status (pending|in_review|published|rejected)
                  · claimed_by · claim_expires_at · version · created_at · updated_at
submission_events id · submission_id · actor_id · type (submitted|claimed|released|edited|
                  published|rejected) · payload jsonb · created_at       ← audit trail
articles          id · submission_id (unique) · slug · title · summary · body · language
                  · category_id · state_id · district_id · mandal_id · village_id
                  · cover_media_id · author_name · source · is_breaking
                  · status (live|unpublished) · published_at · updated_at · published_by
                  · search tsvector (generated)
article_revisions id · article_id · editor_id · before jsonb · after jsonb · created_at
article_stats     article_id · views · likes · shares                 ← batched from API memory
bookmarks         user_id · article_id · created_at      (PK user_id, article_id)
likes             user_id · article_id · created_at      (PK user_id, article_id)
magazines         id · title · subtitle · issue · category · cover_media_id · pdf_media_id
                  · page_count · published_at · status
ads               id · sponsor · headline · description · cta_text · cta_url · image_media_id
                  · weight · starts_at · ends_at · is_active · created_by
ad_stats_daily    ad_id · day · impressions · clicks                  ← batched from API memory
devices           id · user_id (nullable) · fcm_token (unique) · platform · district_id
                  · language · last_seen_at
app_config        key · value jsonb   (ad frequency, magazine slot, min app version…)
```

**Key indexes:**
- `articles (district_id, published_at desc, id) where status='live'` for the district-first part of the feed
- `articles (published_at desc, id) where status='live'` for the main feed
- `articles (category_id, published_at desc, id)`
- `articles using gin(search)`, plus `pg_trgm` on `title` for Telugu and partial matches (the `simple` text-search config is used because Postgres has no Telugu stemmer)
- `submissions (status, created_at)` and `submissions (submitter_id, created_at desc)`

**Rough data size after 1 year:** about 180k articles (around 1 GB with indexes) and about 28k locations. That's small for Postgres. Images live in Storage, not in the database.

### Location data
Source of truth: the **LGD (Local Government Directory)** export for Telangana and Andhra Pradesh, which gives official codes, English names and the hierarchy. The client's Telugu list is used to fill and check `name_te`. `scripts/import-lgd.ts` is idempotent: it inserts new places, updates renamed or moved ones, and deactivates removed ones (rows are never deleted, because articles reference them). Known problems in the client's list that the import has to resolve: duplicate entries, notes mixed in as names, mandals listed under two districts, and the recent new AP districts.

## 4. Key flows

### 4.1 Feed: district first, then everything
`GET /v1/feed?district=<lgd>&cursor=<opaque>&limit=20`

1. **Phase A:** live articles where `district_id = :district and published_at > now() - 48h`, newest first.
2. **Phase B:** all live articles not already shown in phase A, newest first.
3. The cursor encodes `(phase, published_at, id)`, giving keyset pagination. No `OFFSET`, so every page is equally fast.
4. The server mixes in **ads every N articles and a magazine at slot M**, with N and M read from `app_config`. The response is `items: [{type: 'article'|'ad'|'magazine', …}]`, so ad frequency can change without an app release.
5. Without `district`, the feed is phase B only.

**Caching:** `Cache-Control: public, s-maxage=30, stale-while-revalidate=120`. There are at most about 62 different first pages (61 districts plus the all-districts feed), so Cloudflare absorbs almost all feed traffic and Postgres sees a few queries per minute per district. Each API instance also keeps those first pages in memory for 15 seconds as a second layer. A new article appears within about 30 seconds. A breaking story also triggers an explicit cache purge.

**Replacing the realtime connection:** the app no longer holds one open database connection per phone. Instead it calls `GET /v1/feed/head?district=` (cached for 15 seconds) every 60 seconds while it's in the foreground, and shows a "New stories" pill when the newest id changes. Breaking news reaches users by push.

### 4.2 Submission (freelancer or employee)
1. `POST /v1/uploads {kind, contentType, size}` checks type and size (images ≤ 10 MB) and returns a **signed upload URL** plus a `media_id`.
2. The app uploads the file straight to Storage's private `raw` bucket, so the API never carries file bytes.
3. `POST /v1/submissions {…, cover_media_id}` runs one transaction:
   - takes an advisory lock on the user and counts today's submissions (**IST day**). Freelancers are limited to 10/day; the limit is configurable.
   - inserts the submission and a `submitted` event.
4. A worker job processes the image: resize to 320/640/1080 px WebP, **strip EXIF including GPS** (to protect reporters), write to the public `media` bucket, and set `media.status = ready`.

### 4.3 Editorial workflow
- **Claim** is a single atomic statement:
  `UPDATE submissions SET claimed_by=$me, claim_expires_at=now()+15 min, status='in_review' WHERE id=$id AND (claimed_by IS NULL OR claim_expires_at < now() OR claimed_by=$me) RETURNING *`
  If no row comes back, another editor has it.
- **Heartbeat** every 60 seconds extends the claim. Abandoned claims free themselves after 15 minutes, with no cleanup job needed.
- **Save draft** is `PATCH` with a `version` check (optimistic locking), so two tabs can't overwrite each other.
- **Publish** is one transaction: verify the claim, insert the article, set the submission to `published`, write an event. After commit, jobs are queued to clear the cache and, if `is_breaking`, send a push.
- **Reject** is one transaction: set status, then write an event with the reason. The submitter sees the reason but never the editor's identity.
- **Editing a live article** writes an `article_revisions` row. **Delete** sets the article to `unpublished` (a soft delete) and clears the cache.

### 4.4 Counters (views, likes, ad impressions and clicks)
The app batches events and sends them to `POST /v1/events`. Each API instance adds them to in-memory counters and writes one batched `UPSERT` to `article_stats` and `ad_stats_daily` every 30 seconds (and on shutdown), so 10k users generating events never hit Postgres row by row. A crash can lose up to 30 seconds of view counts, which is acceptable for analytics.

### 4.5 Push notifications
The app registers its FCM token with `POST /v1/devices`. Devices subscribe to topics `all`, `district_<lgd>` and `lang_<code>`. For breaking news, an editor marks the article (or calls `POST /v1/editor/notifications`). The worker sends **one** FCM topic message, and Firebase handles delivery to all devices. Before sending, the worker pre-warms the article's cache so the wave of opens lands on Cloudflare.

### 4.6 Account deletion
`DELETE /v1/me` sets `deleted_at` and queues a job that anonymises the profile, removes bookmarks, likes and devices, and deletes the auth user through the Supabase Admin API. Submissions are kept and reassigned to an anonymised placeholder, because they're editorial records.

## 5. Authentication and authorisation
- Supabase Auth issues JWTs. A **Custom Access Token Hook** adds `app_role` from `profiles.role` to the token.
- The API verifies tokens **offline** against Supabase's JWKS (asymmetric signing keys), so there's no per-request call to Supabase. A role check happens in route middleware: `requireRole('editor','admin')`.
- A role change takes effect on the next token refresh, within 1 hour. Admin role changes also revoke the user's sessions so it applies immediately.
- **Test accounts:** `scripts/seed-test-users.ts` creates `admin@`, `editor@`, `freelancer@`, `employee@` and `reader@` test users through the Admin API. Passwords come from `.env` and are never in the app or the repo.
- Client-side role checks in Flutter remain **for routing the UI only**. Security is enforced by the API.

## 6. API surface (v1)

| Area | Endpoints |
|---|---|
| **Public (cached)** | `GET /feed`, `/feed/head`, `/articles/:id`, `/categories`, `/locations?parent=&level=`, `/search?q=`, `/magazines`, `/magazines/:id`, `/config` |
| **Reader** | `GET/PATCH /me`, `DELETE /me`, `GET /me/bookmarks`, `PUT/DELETE /me/bookmarks/:articleId`, `PUT/DELETE /me/likes/:articleId`, `GET /me/state?ids=` (liked/saved flags), `POST /devices`, `POST /events` |
| **Contributor** | `POST /uploads`, `POST /submissions`, `GET /me/submissions`, `GET /me/submissions/:id`, `GET /me/submission-quota` |
| **Editor** | `GET /editor/queue`, `GET /editor/stats`, `POST /editor/submissions/:id/{claim,heartbeat,release,publish,reject}`, `PATCH /editor/submissions/:id`, `GET/PATCH/DELETE /editor/articles/:id`, `POST /editor/notifications` |
| **Admin** | `GET /admin/stats` (one SQL query using `FILTER`), `GET /admin/users?q=&role=&cursor=`, `PATCH /admin/users/:id`, CRUD `/admin/ads`, `/admin/magazines`, `/admin/categories`, `GET /admin/ads/:id/report`, `PATCH /admin/config` |

Every list endpoint uses cursor pagination with a maximum `limit` of 50. Errors share one shape: `{error: {code, message}}`.

## 7. Scaling to 10,000 concurrent users

| Layer | Launch | ~4k concurrent | 10k concurrent |
|---|---|---|---|
| Cloudflare | Free or Pro | Pro | Pro (+ WAF rules) |
| API (Cloud Run) | min 1, max 4 × 1 vCPU / 1 GB | min 2, max 6 × 1 vCPU / 1 GB | min 2, max 10 × 1 vCPU / 2 GB (autoscale on concurrency ≈ 80 requests per instance) |
| Worker (Cloud Run) | 1 × 0.5 vCPU, always on | 1 × 1 vCPU | 1–2 × 1 vCPU |
| Supabase compute | Small | Medium | Large (+ read replica if needed) |
| Redis | not used | not used | add Upstash (Mumbai) only if load tests show it's needed |

Estimated load at 10k concurrent: about 500–1,000 requests per second, with bursts of 2–5k per second after a breaking-news push. With a CDN hit rate above 90%, the origin sees roughly 100–300 requests per second.

**Performance targets:** origin p95 under 250 ms, cached p95 under 80 ms in India, error rate under 0.1%.

**Load test before launch (k6):**
1. Steady: 10k virtual users with realistic think time (feed → article → back), for 30 minutes.
2. Spike: 1k → 10k users in 60 seconds, all opening one article (a simulated breaking-news push).
3. Write mix: 500 publishes per hour plus editor activity running alongside both of the above.

## 8. Estimated monthly cost (USD, rough; verify before committing)

| Stage | Supabase | Google Cloud Run (API + worker + logs) | Cloudflare | **Total** |
|---|---|---|---|---|
| Launch | ~$25–40 | ~$25–45 | $0–25 | **~$50–110** |
| ~4k concurrent | ~$85–120 | ~$80–150 | $25 | **~$190–300** |
| 10k concurrent | ~$150–260 | ~$150–300 | $25+ | **~$330–590** |

Images are served through Cloudflare, so Supabase egress stays low. FCM is free. Cloud Run needs the Firebase project on the pay-as-you-go **Blaze** plan.

## 9. Security and compliance
- All stored data is in Mumbai (Supabase `ap-south-1`, Cloud Run `asia-south1`). Cloudflare caches only public content at its edges.
- **Caveats:** FCM (Google) processes device tokens, and Sentry stores error events outside India. Personal data is scrubbed from both, and Sentry can be swapped for a self-hosted option if strict residency is required.
- Rate limits: per-IP rules at Cloudflare (the main defence) plus per-user limits in each API instance. Auth endpoints get stricter Cloudflare rules.
- Secrets live in Google Secret Manager. The service-role key exists only in the API and worker, never in the app.
- Postgres has point-in-time recovery enabled. A full backup is restored once a month as a test.

## 10. Flutter changes needed
1. Add an API client (`dio`) with JWT injection. Keep `supabase_flutter` **for auth and signed uploads only**.
2. Remove all direct table queries, the realtime subscription and the `demo_*` data.
3. Render the feed from the server's `items` list (articles, ads, magazines).
4. Key bookmarks and likes by article **id**, synced through `/me/*`. Store location as LGD ids.
5. Remove the fake Google and OTP screens until real login methods are added. Fix account deletion.

## 11. Delivery plan

| Phase | Deliverable |
|---|---|
| 0. Setup | Repo, Supabase Mumbai project, local Docker environment, CI, environment files |
| 1. Data | Schema and migrations, LGD import, categories, seeded test users |
| 2. Read API | Feed (district first), article, locations, categories, search, config, plus caching |
| 3. Newsroom | Uploads and image worker, submissions, editor workflow, audit trail |
| 4. Admin | Users, ads, magazines, stats, events and counters |
| 5. App integration | Flutter moved to the API |
| 6. Launch readiness | Push notifications, Cloudflare and Cloud Run deployment, k6 load tests, monitoring, backups |
| Later | Phone OTP, translation at publish time, audio news, ad targeting, reporter payments |

## 12. Open items
- The existing Supabase project (`wtzoszozevnljfhiykpj`) belongs to another account. Either get access to it, or (recommended) create a fresh **Mumbai** project in a client-owned organisation and migrate any real data.
- Domain name for the API and images (e.g. `api.<domain>`, `img.<domain>`).
- Cloudflare account and Firebase project: the client will provide these later. Until then, everything runs locally in Docker.

## 13. Hosting plan: demo now, AWS for production

### 13.1 Client demo (no AWS)
| Piece | Service | Cost/month |
|---|---|---|
| Database, auth, storage | Supabase **free** project in Mumbai (demo data only; pauses after 7 days of inactivity) | $0 |
| API + worker | **Render** Starter web service, Singapore, one container running the API and worker together (`WORKER_INLINE=true`) | $7 (the free tier sleeps and takes about 50 seconds to wake, which is bad for a live demo) |
| Flutter app | Android APK shared directly, plus Flutter **web** build on Vercel | $0 |
| **Total** | | **≈ $0–7** |

The demo holds test data only, so the India-only residency rule does not apply to it. Production moves everything to Mumbai.

### 13.2 Production on AWS (Mumbai `ap-south-1`)
Supabase (Pro, Mumbai) remains the database, auth and storage. AWS runs our code:

| AWS service | Used for |
|---|---|
| **ECS on Fargate** (ARM/Graviton) | Two services: `api` (Express, autoscaling) and `worker` (pg-boss jobs) |
| **Application Load Balancer** + **ACM** (free TLS certificate) | HTTPS entry point behind Cloudflare, health checks, spreads traffic across API containers |
| **ECR** | Stores Docker images built by GitHub Actions |
| **Secrets Manager** | Database URL, Supabase service key, Firebase credentials |
| **CloudWatch** (Logs, Metrics, Alarms) | Logs, CPU/latency dashboards, alerts |
| **VPC** (public subnets, security groups) | Networking. Tasks run in public subnets that accept traffic only from the ALB, which **avoids a NAT Gateway (~$45/month)** |
| *Later, if needed:* **ElastiCache (Valkey/Redis)** | Shared cache and rate limits, only if load tests require it |
| *Not needed:* Route 53, WAF, CloudFront, RDS, Cognito, S3 | Cloudflare covers DNS, WAF and CDN; Supabase covers the database, auth and storage |

### 13.3 Estimated monthly cost: production (USD, approximate)
| | Launch (100–250 concurrent) | ~4k concurrent | 10k concurrent |
|---|---|---|---|
| Fargate: API | 2 × 0.5 vCPU/1 GB ≈ $35 | avg 3 × 1 vCPU/2 GB ≈ $105 | avg 4–5 × 1 vCPU/2 GB ≈ $160 |
| Fargate: worker | 1 × 0.25 vCPU ≈ $8 | 1 × 0.5 vCPU ≈ $18 | 2 × 0.5 vCPU ≈ $36 |
| Load balancer | ≈ $22 | ≈ $30 | ≈ $45 |
| CloudWatch logs and alarms | ≈ $5 | ≈ $15 | ≈ $30 |
| ECR, Secrets Manager, public IPv4 | ≈ $12 | ≈ $15 | ≈ $20 |
| Data transfer out (API JSON to Cloudflare) | ≈ $5 | ≈ $20 | ≈ $40 |
| ElastiCache (optional) | — | — | ≈ $0–25 |
| **AWS subtotal** | **≈ $85** | **≈ $205** | **≈ $330–355** |
| Supabase Pro + compute | ≈ $30 (Small) | ≈ $75 (Medium) | ≈ $125 (Large), +$110 with a read replica |
| Cloudflare | $0 | $25 (Pro) | $25 (Pro) |
| Firebase (FCM) | $0 | $0 | $0 |
| **Total** | **≈ $115** | **≈ $305** | **≈ $480–620** |

Notes:
- **AWS adds 18% GST** for Indian accounts, on top of these figures.
- A 1-year **Compute Savings Plan** cuts Fargate costs by about 20%.
- Figures are estimates from public on-demand prices; confirm them in the AWS Pricing Calculator before committing to a budget.

## 14. Observability: finding and fixing problems fast

| Need | Tool | Notes |
|---|---|---|
| Errors and crashes (API **and** Flutter app) | **Sentry** (`@sentry/node`, `sentry_flutter`) | Stack traces, release tracking tied to the git commit, performance traces (slow endpoints and DB queries). Personal data is scrubbed (`sendDefaultPii: false`, `beforeSend`) because Sentry stores data in the US or EU |
| Logs | `pino` JSON logs → **CloudWatch Logs** (production) / Render logs (demo) | Every request is logged with a **request id**, user id, route, status and duration. The same id goes into Sentry and into every error response, so a user's screenshot leads straight to the log line |
| Metrics and dashboards | **CloudWatch** (ECS Container Insights + ALB metrics) | CPU, memory, request count, p95/p99 latency, 5xx rate, task count |
| Uptime and alerts | **Better Stack** (or UptimeRobot), checking `/healthz` and `/v1/feed` every minute from India | Phone, email or Slack alert within about a minute of an outage |
| Database health | Supabase dashboard + `pg_stat_statements` | Slow queries, connections, CPU |
| Edge and traffic | Cloudflare Analytics | Cache hit ratio, requests, blocked attacks |
| Load testing | k6 | Proves the 10k-concurrent target before launch |

**Alerts (CloudWatch alarms + Sentry rules, sent to email or Slack):**
- 5xx rate above 1% for 5 minutes
- p95 latency above 500 ms for 5 minutes
- API CPU above 80%
- Worker job failures, or a queue backlog over 100 jobs
- A new Sentry issue in a release
- Uptime check fails twice in a row

**Fast recovery:**
- `/healthz` (process up) and `/readyz` (database reachable) endpoints
- One-click rollback to the previous ECS task definition
- Feature switches in `app_config` (for example, turning ads or push notifications off) that take effect without a deploy
- A short runbook in `backend/docs/runbook.md` covering what each alert means and the first steps to take

## 15. Metrics to record (for reports and the resume)
Record these from k6 runs, CloudWatch, Cloudflare and Sentry, **using real measured values only**:
- Peak concurrent virtual users sustained in the load test, and requests per second
- p50/p95/p99 API latency, at the origin and through Cloudflare
- CDN cache hit ratio, and the resulting cut in database queries
- Error rate under load, and uptime percentage per month
- Feed query time with keyset pagination compared with the original fetch-everything approach
- Image payload reduction from WebP resizing (average KB before and after)
- Time from an editor pressing publish to the story appearing in the app
- Infrastructure cost per 1,000 daily active users
- Crash-free sessions in the app (Sentry)
