import { sql } from 'drizzle-orm'
import {
  bigint,
  boolean,
  customType,
  date,
  index,
  integer,
  jsonb,
  pgSchema,
  primaryKey,
  smallint,
  text,
  timestamp,
  uniqueIndex,
  uuid,
} from 'drizzle-orm/pg-core'

// All application tables live in the `app` schema. Supabase's auto-generated
// REST API only exposes `public`, so nothing here is reachable with the
// publishable key — every read/write goes through our API.
export const app = pgSchema('app')

const tsvector = customType<{ data: string }>({ dataType: () => 'tsvector' })
const ts = (name: string) => timestamp(name, { withTimezone: true, mode: 'date' })

// ---------------------------------------------------------------- enums

export const roleEnum = app.enum('role', ['reader', 'freelancer', 'employee', 'editor', 'admin'])
export const locationLevelEnum = app.enum('location_level', ['state', 'district', 'mandal', 'village'])
export const submissionStatusEnum = app.enum('submission_status', ['pending', 'in_review', 'published', 'rejected'])
export const articleStatusEnum = app.enum('article_status', ['live', 'unpublished'])
export const mediaKindEnum = app.enum('media_kind', ['image', 'pdf', 'video'])
export const applicationStatusEnum = app.enum('application_status', ['pending', 'approved', 'rejected'])
export const adTargetScopeEnum = app.enum('ad_target_scope', ['all', 'state', 'district'])
export const wishKindEnum = app.enum('wish_kind', ['birthday', 'anniversary'])
export const mediaStatusEnum = app.enum('media_status', ['pending', 'ready', 'failed'])
export const submissionEventEnum = app.enum('submission_event_type', [
  'submitted',
  'claimed',
  'released',
  'edited',
  'published',
  'rejected',
])

// ---------------------------------------------------------------- reference data

/** LGD-coded hierarchy: state → district → mandal (sub-district) → village. */
export const locations = app.table(
  'locations',
  {
    id: integer('id').primaryKey(), // LGD code (unique across levels in practice; level disambiguates)
    level: locationLevelEnum('level').notNull(),
    parentId: integer('parent_id'),
    stateId: integer('state_id'),
    districtId: integer('district_id'),
    mandalId: integer('mandal_id'),
    nameEn: text('name_en').notNull(),
    nameTe: text('name_te'),
    isActive: boolean('is_active').notNull().default(true),
    updatedAt: ts('updated_at').notNull().defaultNow(),
  },
  (t) => [
    index('locations_parent_idx').on(t.parentId, t.level),
    index('locations_level_idx').on(t.level),
    index('locations_name_trgm_idx').using('gin', sql`${t.nameEn} extensions.gin_trgm_ops`),
  ],
)

export const categories = app.table('categories', {
  id: smallint('id').primaryKey(),
  slug: text('slug').notNull().unique(),
  nameEn: text('name_en').notNull(),
  nameTe: text('name_te').notNull(),
  nameHi: text('name_hi').notNull(),
  sortOrder: smallint('sort_order').notNull().default(0),
  isActive: boolean('is_active').notNull().default(true),
})

// ---------------------------------------------------------------- people

/** One row per Supabase Auth user (id = auth.users.id). */
export const profiles = app.table(
  'profiles',
  {
    id: uuid('id').primaryKey(),
    email: text('email'),
    role: roleEnum('role').notNull().default('reader'),
    fullName: text('full_name'),
    language: text('language').notNull().default('te'),
    homeDistrictId: integer('home_district_id').references(() => locations.id),
    createdAt: ts('created_at').notNull().defaultNow(),
    updatedAt: ts('updated_at').notNull().defaultNow(),
    deletedAt: ts('deleted_at'),
    // Set when an admin removes a reporter/freelancer: they can no longer sign in or submit.
    disabledAt: ts('disabled_at'),
  },
  (t) => [index('profiles_role_idx').on(t.role)],
)

/**
 * Reporter / freelancer sign-up requests. The applicant gets a normal (reader) account right away;
 * an admin approving the application is what upgrades their role so they can submit news.
 */
export const contributorApplications = app.table(
  'contributor_applications',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    requestedRole: roleEnum('requested_role').notNull(), // 'employee' (reporter) or 'freelancer'
    fullName: text('full_name').notNull(),
    mobile: text('mobile').notNull(),
    email: text('email').notNull(),
    address: text('address'),
    stateId: integer('state_id').references(() => locations.id),
    districtId: integer('district_id')
      .notNull()
      .references(() => locations.id),
    mandalId: integer('mandal_id').references(() => locations.id),
    status: applicationStatusEnum('status').notNull().default('pending'),
    reviewedBy: uuid('reviewed_by').references(() => profiles.id),
    reviewedAt: ts('reviewed_at'),
    rejectionReason: text('rejection_reason'),
    createdAt: ts('created_at').notNull().defaultNow(),
    updatedAt: ts('updated_at').notNull().defaultNow(),
  },
  (t) => [
    index('contributor_applications_status_idx').on(t.status, t.createdAt),
    index('contributor_applications_user_idx').on(t.userId, t.createdAt),
    // At most one open application per person.
    uniqueIndex('contributor_applications_one_pending').on(t.userId).where(sql`status = 'pending'`),
  ],
)

// ---------------------------------------------------------------- media

export const media = app.table('media', {
  id: uuid('id').primaryKey().defaultRandom(),
  ownerId: uuid('owner_id').references(() => profiles.id),
  kind: mediaKindEnum('kind').notNull(),
  rawKey: text('raw_key').notNull(),
  contentType: text('content_type').notNull(),
  sizeBytes: integer('size_bytes').notNull(),
  // { "320": "media/<id>/320.webp", "640": ..., "1080": ... } for images; { "pdf": key } for PDFs; { "video": key } for videos
  variants: jsonb('variants').$type<Record<string, string>>(),
  width: integer('width'),
  height: integer('height'),
  status: mediaStatusEnum('status').notNull().default('pending'),
  error: text('error'),
  createdAt: ts('created_at').notNull().defaultNow(),
})

// ---------------------------------------------------------------- newsroom

const storyColumns = () => ({
  title: text('title').notNull(),
  summary: text('summary').notNull(),
  body: text('body').notNull(),
  language: text('language').notNull(), // ISO code: te, en, hi, ...
  categoryId: smallint('category_id')
    .notNull()
    .references(() => categories.id),
  stateId: integer('state_id')
    .notNull()
    .references(() => locations.id),
  districtId: integer('district_id')
    .notNull()
    .references(() => locations.id),
  mandalId: integer('mandal_id').references(() => locations.id),
  villageId: integer('village_id').references(() => locations.id),
  coverMediaId: uuid('cover_media_id').references(() => media.id),
  authorName: text('author_name').notNull(),
  source: text('source'),
  // Follow-up linking: `relatedAnchor` (a word/phrase in the body) opens `relatedArticleId`.
  relatedArticleId: uuid('related_article_id'),
  relatedAnchor: text('related_anchor'),
})

export const submissions = app.table(
  'submissions',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    submitterId: uuid('submitter_id')
      .notNull()
      .references(() => profiles.id),
    ...storyColumns(),
    status: submissionStatusEnum('status').notNull().default('pending'),
    claimedBy: uuid('claimed_by').references(() => profiles.id),
    claimExpiresAt: ts('claim_expires_at'),
    version: integer('version').notNull().default(1),
    createdAt: ts('created_at').notNull().defaultNow(),
    updatedAt: ts('updated_at').notNull().defaultNow(),
  },
  (t) => [
    index('submissions_status_idx').on(t.status, t.createdAt),
    index('submissions_submitter_idx').on(t.submitterId, t.createdAt),
  ],
)

export const submissionEvents = app.table(
  'submission_events',
  {
    id: bigint('id', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
    submissionId: uuid('submission_id')
      .notNull()
      .references(() => submissions.id, { onDelete: 'cascade' }),
    actorId: uuid('actor_id').references(() => profiles.id),
    type: submissionEventEnum('type').notNull(),
    // For 'rejected': { reason } — shown to the submitter without the editor's identity.
    payload: jsonb('payload').$type<Record<string, unknown>>(),
    createdAt: ts('created_at').notNull().defaultNow(),
  },
  (t) => [index('submission_events_submission_idx').on(t.submissionId, t.createdAt)],
)

export const articles = app.table(
  'articles',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    submissionId: uuid('submission_id').references(() => submissions.id),
    ...storyColumns(),
    isBreaking: boolean('is_breaking').notNull().default(false),
    status: articleStatusEnum('status').notNull().default('live'),
    publishedAt: ts('published_at').notNull().defaultNow(),
    updatedAt: ts('updated_at').notNull().defaultNow(),
    publishedBy: uuid('published_by').references(() => profiles.id),
    search: tsvector('search').generatedAlwaysAs(
      sql`to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(body, ''))`,
    ),
  },
  (t) => [
    uniqueIndex('articles_submission_uidx').on(t.submissionId),
    index('articles_feed_idx').on(t.publishedAt.desc(), t.id.desc()).where(sql`status = 'live'`),
    index('articles_district_feed_idx')
      .on(t.districtId, t.publishedAt.desc(), t.id.desc())
      .where(sql`status = 'live'`),
    index('articles_category_feed_idx')
      .on(t.categoryId, t.publishedAt.desc(), t.id.desc())
      .where(sql`status = 'live'`),
    index('articles_search_idx').using('gin', t.search),
    index('articles_title_trgm_idx').using('gin', sql`${t.title} extensions.gin_trgm_ops`),
  ],
)

export const articleRevisions = app.table('article_revisions', {
  id: bigint('id', { mode: 'number' }).primaryKey().generatedAlwaysAsIdentity(),
  articleId: uuid('article_id')
    .notNull()
    .references(() => articles.id, { onDelete: 'cascade' }),
  editorId: uuid('editor_id').references(() => profiles.id),
  before: jsonb('before').notNull(),
  after: jsonb('after').notNull(),
  createdAt: ts('created_at').notNull().defaultNow(),
})

export const articleStats = app.table('article_stats', {
  articleId: uuid('article_id')
    .primaryKey()
    .references(() => articles.id, { onDelete: 'cascade' }),
  views: bigint('views', { mode: 'number' }).notNull().default(0),
  likes: bigint('likes', { mode: 'number' }).notNull().default(0),
  shares: bigint('shares', { mode: 'number' }).notNull().default(0),
  comments: bigint('comments', { mode: 'number' }).notNull().default(0),
})

export const comments = app.table(
  'comments',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    articleId: uuid('article_id')
      .notNull()
      .references(() => articles.id, { onDelete: 'cascade' }),
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    body: text('body').notNull(),
    createdAt: ts('created_at').notNull().defaultNow(),
    deletedAt: ts('deleted_at'),
    deletedBy: uuid('deleted_by').references(() => profiles.id),
  },
  (t) => [index('comments_article_idx').on(t.articleId, t.createdAt.desc(), t.id.desc()).where(sql`deleted_at IS NULL`)],
)

// ---------------------------------------------------------------- reader state

export const bookmarks = app.table(
  'bookmarks',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    articleId: uuid('article_id')
      .notNull()
      .references(() => articles.id, { onDelete: 'cascade' }),
    createdAt: ts('created_at').notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.articleId] }), index('bookmarks_user_idx').on(t.userId, t.createdAt)],
)

export const likes = app.table(
  'likes',
  {
    userId: uuid('user_id')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    articleId: uuid('article_id')
      .notNull()
      .references(() => articles.id, { onDelete: 'cascade' }),
    createdAt: ts('created_at').notNull().defaultNow(),
  },
  (t) => [primaryKey({ columns: [t.userId, t.articleId] })],
)

export const devices = app.table('devices', {
  id: uuid('id').primaryKey().defaultRandom(),
  userId: uuid('user_id').references(() => profiles.id, { onDelete: 'set null' }),
  fcmToken: text('fcm_token').notNull().unique(),
  platform: text('platform').notNull(),
  districtId: integer('district_id').references(() => locations.id),
  language: text('language'),
  lastSeenAt: ts('last_seen_at').notNull().defaultNow(),
})

// ---------------------------------------------------------------- monetisation & extras

export const magazines = app.table('magazines', {
  id: uuid('id').primaryKey().defaultRandom(),
  title: text('title').notNull(),
  subtitle: text('subtitle'),
  issue: text('issue').notNull(),
  category: text('category'),
  coverMediaId: uuid('cover_media_id').references(() => media.id),
  coverUrl: text('cover_url'), // external URL fallback (demo data)
  pdfMediaId: uuid('pdf_media_id').references(() => media.id),
  pdfUrl: text('pdf_url'),
  pageCount: integer('page_count'),
  isPublished: boolean('is_published').notNull().default(true),
  publishedAt: ts('published_at').notNull().defaultNow(),
})

export const ads = app.table('ads', {
  id: uuid('id').primaryKey().defaultRandom(),
  sponsor: text('sponsor').notNull(),
  headline: text('headline').notNull(),
  description: text('description'),
  tag: text('tag'),
  ctaText: text('cta_text'),
  ctaUrl: text('cta_url'),
  imageMediaId: uuid('image_media_id').references(() => media.id),
  imageUrl: text('image_url'), // external URL fallback (demo data)
  weight: integer('weight').notNull().default(1),
  startsAt: ts('starts_at'),
  endsAt: ts('ends_at'),
  // 4-page sliding campaigns: [{ pageIndex, tag, headline, description, imageUrl, highlightBadge }]
  slides: jsonb('slides').$type<Record<string, unknown>[]>(),
  scheduleType: text('schedule_type'), // oneDay | threePlusOne | custom
  category: text('category'),
  // Where the ad is shown: everywhere, one state, or one district.
  targetScope: adTargetScopeEnum('target_scope').notNull().default('all'),
  targetStateId: integer('target_state_id').references(() => locations.id),
  targetDistrictId: integer('target_district_id').references(() => locations.id),
  isActive: boolean('is_active').notNull().default(true),
  createdBy: uuid('created_by').references(() => profiles.id),
  createdAt: ts('created_at').notNull().defaultNow(),
})

export const adStatsDaily = app.table(
  'ad_stats_daily',
  {
    adId: uuid('ad_id')
      .notNull()
      .references(() => ads.id, { onDelete: 'cascade' }),
    day: date('day').notNull(),
    impressions: bigint('impressions', { mode: 'number' }).notNull().default(0),
    clicks: bigint('clicks', { mode: 'number' }).notNull().default(0),
  },
  (t) => [primaryKey({ columns: [t.adId, t.day] })],
)

/** Birthday / wedding-anniversary wishes posters sent by readers; shown after an editor approves. */
export const wishes = app.table(
  'wishes',
  {
    id: uuid('id').primaryKey().defaultRandom(),
    kind: wishKindEnum('kind').notNull(),
    photoMediaId: uuid('photo_media_id').references(() => media.id),
    recipientName: text('recipient_name').notNull(),
    message: text('message').notNull(),
    fromNames: text('from_names').notNull(),
    districtId: integer('district_id').references(() => locations.id),
    status: applicationStatusEnum('status').notNull().default('pending'),
    submittedBy: uuid('submitted_by')
      .notNull()
      .references(() => profiles.id, { onDelete: 'cascade' }),
    reviewedBy: uuid('reviewed_by').references(() => profiles.id),
    reviewedAt: ts('reviewed_at'),
    rejectionReason: text('rejection_reason'),
    createdAt: ts('created_at').notNull().defaultNow(),
  },
  (t) => [index('wishes_status_idx').on(t.status, t.createdAt.desc())],
)

export const appConfig = app.table('app_config', {
  key: text('key').primaryKey(),
  value: jsonb('value').notNull(),
  updatedAt: ts('updated_at').notNull().defaultNow(),
})
