CREATE SCHEMA IF NOT EXISTS "app";
--> statement-breakpoint
CREATE TYPE "app"."article_status" AS ENUM('live', 'unpublished');--> statement-breakpoint
CREATE TYPE "app"."location_level" AS ENUM('state', 'district', 'mandal', 'village');--> statement-breakpoint
CREATE TYPE "app"."media_kind" AS ENUM('image', 'pdf');--> statement-breakpoint
CREATE TYPE "app"."media_status" AS ENUM('pending', 'ready', 'failed');--> statement-breakpoint
CREATE TYPE "app"."role" AS ENUM('reader', 'freelancer', 'employee', 'editor', 'admin');--> statement-breakpoint
CREATE TYPE "app"."submission_event_type" AS ENUM('submitted', 'claimed', 'released', 'edited', 'published', 'rejected');--> statement-breakpoint
CREATE TYPE "app"."submission_status" AS ENUM('pending', 'in_review', 'published', 'rejected');--> statement-breakpoint
CREATE TABLE "app"."ad_stats_daily" (
	"ad_id" uuid NOT NULL,
	"day" date NOT NULL,
	"impressions" bigint DEFAULT 0 NOT NULL,
	"clicks" bigint DEFAULT 0 NOT NULL,
	CONSTRAINT "ad_stats_daily_ad_id_day_pk" PRIMARY KEY("ad_id","day")
);
--> statement-breakpoint
CREATE TABLE "app"."ads" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"sponsor" text NOT NULL,
	"headline" text NOT NULL,
	"description" text,
	"tag" text,
	"cta_text" text,
	"cta_url" text,
	"image_media_id" uuid,
	"image_url" text,
	"weight" integer DEFAULT 1 NOT NULL,
	"starts_at" timestamp with time zone,
	"ends_at" timestamp with time zone,
	"is_active" boolean DEFAULT true NOT NULL,
	"created_by" uuid,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."app_config" (
	"key" text PRIMARY KEY NOT NULL,
	"value" jsonb NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."article_revisions" (
	"id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "app"."article_revisions_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"article_id" uuid NOT NULL,
	"editor_id" uuid,
	"before" jsonb NOT NULL,
	"after" jsonb NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."article_stats" (
	"article_id" uuid PRIMARY KEY NOT NULL,
	"views" bigint DEFAULT 0 NOT NULL,
	"likes" bigint DEFAULT 0 NOT NULL,
	"shares" bigint DEFAULT 0 NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."articles" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"submission_id" uuid,
	"title" text NOT NULL,
	"summary" text NOT NULL,
	"body" text NOT NULL,
	"language" text NOT NULL,
	"category_id" smallint NOT NULL,
	"state_id" integer NOT NULL,
	"district_id" integer NOT NULL,
	"mandal_id" integer,
	"village_id" integer,
	"cover_media_id" uuid,
	"author_name" text NOT NULL,
	"source" text,
	"is_breaking" boolean DEFAULT false NOT NULL,
	"status" "app"."article_status" DEFAULT 'live' NOT NULL,
	"published_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"published_by" uuid,
	"search" "tsvector" GENERATED ALWAYS AS (to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(summary, '') || ' ' || coalesce(body, ''))) STORED
);
--> statement-breakpoint
CREATE TABLE "app"."bookmarks" (
	"user_id" uuid NOT NULL,
	"article_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "bookmarks_user_id_article_id_pk" PRIMARY KEY("user_id","article_id")
);
--> statement-breakpoint
CREATE TABLE "app"."categories" (
	"id" smallint PRIMARY KEY NOT NULL,
	"slug" text NOT NULL,
	"name_en" text NOT NULL,
	"name_te" text NOT NULL,
	"name_hi" text NOT NULL,
	"sort_order" smallint DEFAULT 0 NOT NULL,
	"is_active" boolean DEFAULT true NOT NULL,
	CONSTRAINT "categories_slug_unique" UNIQUE("slug")
);
--> statement-breakpoint
CREATE TABLE "app"."devices" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid,
	"fcm_token" text NOT NULL,
	"platform" text NOT NULL,
	"district_id" integer,
	"language" text,
	"last_seen_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "devices_fcm_token_unique" UNIQUE("fcm_token")
);
--> statement-breakpoint
CREATE TABLE "app"."likes" (
	"user_id" uuid NOT NULL,
	"article_id" uuid NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	CONSTRAINT "likes_user_id_article_id_pk" PRIMARY KEY("user_id","article_id")
);
--> statement-breakpoint
CREATE TABLE "app"."locations" (
	"id" integer PRIMARY KEY NOT NULL,
	"level" "app"."location_level" NOT NULL,
	"parent_id" integer,
	"state_id" integer,
	"district_id" integer,
	"mandal_id" integer,
	"name_en" text NOT NULL,
	"name_te" text,
	"is_active" boolean DEFAULT true NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."magazines" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"title" text NOT NULL,
	"subtitle" text,
	"issue" text NOT NULL,
	"category" text,
	"cover_media_id" uuid,
	"cover_url" text,
	"pdf_media_id" uuid,
	"pdf_url" text,
	"page_count" integer,
	"is_published" boolean DEFAULT true NOT NULL,
	"published_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."media" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"owner_id" uuid,
	"kind" "app"."media_kind" NOT NULL,
	"raw_key" text NOT NULL,
	"content_type" text NOT NULL,
	"size_bytes" integer NOT NULL,
	"variants" jsonb,
	"width" integer,
	"height" integer,
	"status" "app"."media_status" DEFAULT 'pending' NOT NULL,
	"error" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."profiles" (
	"id" uuid PRIMARY KEY NOT NULL,
	"email" text,
	"role" "app"."role" DEFAULT 'reader' NOT NULL,
	"full_name" text,
	"language" text DEFAULT 'te' NOT NULL,
	"home_district_id" integer,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone
);
--> statement-breakpoint
CREATE TABLE "app"."submission_events" (
	"id" bigint PRIMARY KEY GENERATED ALWAYS AS IDENTITY (sequence name "app"."submission_events_id_seq" INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1),
	"submission_id" uuid NOT NULL,
	"actor_id" uuid,
	"type" "app"."submission_event_type" NOT NULL,
	"payload" jsonb,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
CREATE TABLE "app"."submissions" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"submitter_id" uuid NOT NULL,
	"title" text NOT NULL,
	"summary" text NOT NULL,
	"body" text NOT NULL,
	"language" text NOT NULL,
	"category_id" smallint NOT NULL,
	"state_id" integer NOT NULL,
	"district_id" integer NOT NULL,
	"mandal_id" integer,
	"village_id" integer,
	"cover_media_id" uuid,
	"author_name" text NOT NULL,
	"source" text,
	"status" "app"."submission_status" DEFAULT 'pending' NOT NULL,
	"claimed_by" uuid,
	"claim_expires_at" timestamp with time zone,
	"version" integer DEFAULT 1 NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "app"."ad_stats_daily" ADD CONSTRAINT "ad_stats_daily_ad_id_ads_id_fk" FOREIGN KEY ("ad_id") REFERENCES "app"."ads"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD CONSTRAINT "ads_image_media_id_media_id_fk" FOREIGN KEY ("image_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD CONSTRAINT "ads_created_by_profiles_id_fk" FOREIGN KEY ("created_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."article_revisions" ADD CONSTRAINT "article_revisions_article_id_articles_id_fk" FOREIGN KEY ("article_id") REFERENCES "app"."articles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."article_revisions" ADD CONSTRAINT "article_revisions_editor_id_profiles_id_fk" FOREIGN KEY ("editor_id") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."article_stats" ADD CONSTRAINT "article_stats_article_id_articles_id_fk" FOREIGN KEY ("article_id") REFERENCES "app"."articles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_submission_id_submissions_id_fk" FOREIGN KEY ("submission_id") REFERENCES "app"."submissions"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_category_id_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "app"."categories"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_state_id_locations_id_fk" FOREIGN KEY ("state_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_district_id_locations_id_fk" FOREIGN KEY ("district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_mandal_id_locations_id_fk" FOREIGN KEY ("mandal_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_village_id_locations_id_fk" FOREIGN KEY ("village_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_cover_media_id_media_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD CONSTRAINT "articles_published_by_profiles_id_fk" FOREIGN KEY ("published_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."bookmarks" ADD CONSTRAINT "bookmarks_user_id_profiles_id_fk" FOREIGN KEY ("user_id") REFERENCES "app"."profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."bookmarks" ADD CONSTRAINT "bookmarks_article_id_articles_id_fk" FOREIGN KEY ("article_id") REFERENCES "app"."articles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."devices" ADD CONSTRAINT "devices_user_id_profiles_id_fk" FOREIGN KEY ("user_id") REFERENCES "app"."profiles"("id") ON DELETE set null ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."devices" ADD CONSTRAINT "devices_district_id_locations_id_fk" FOREIGN KEY ("district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."likes" ADD CONSTRAINT "likes_user_id_profiles_id_fk" FOREIGN KEY ("user_id") REFERENCES "app"."profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."likes" ADD CONSTRAINT "likes_article_id_articles_id_fk" FOREIGN KEY ("article_id") REFERENCES "app"."articles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."magazines" ADD CONSTRAINT "magazines_cover_media_id_media_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."magazines" ADD CONSTRAINT "magazines_pdf_media_id_media_id_fk" FOREIGN KEY ("pdf_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."media" ADD CONSTRAINT "media_owner_id_profiles_id_fk" FOREIGN KEY ("owner_id") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."profiles" ADD CONSTRAINT "profiles_home_district_id_locations_id_fk" FOREIGN KEY ("home_district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submission_events" ADD CONSTRAINT "submission_events_submission_id_submissions_id_fk" FOREIGN KEY ("submission_id") REFERENCES "app"."submissions"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submission_events" ADD CONSTRAINT "submission_events_actor_id_profiles_id_fk" FOREIGN KEY ("actor_id") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_submitter_id_profiles_id_fk" FOREIGN KEY ("submitter_id") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_category_id_categories_id_fk" FOREIGN KEY ("category_id") REFERENCES "app"."categories"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_state_id_locations_id_fk" FOREIGN KEY ("state_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_district_id_locations_id_fk" FOREIGN KEY ("district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_mandal_id_locations_id_fk" FOREIGN KEY ("mandal_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_village_id_locations_id_fk" FOREIGN KEY ("village_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_cover_media_id_media_id_fk" FOREIGN KEY ("cover_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD CONSTRAINT "submissions_claimed_by_profiles_id_fk" FOREIGN KEY ("claimed_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE UNIQUE INDEX "articles_submission_uidx" ON "app"."articles" USING btree ("submission_id");--> statement-breakpoint
CREATE INDEX "articles_feed_idx" ON "app"."articles" USING btree ("published_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE status = 'live';--> statement-breakpoint
CREATE INDEX "articles_district_feed_idx" ON "app"."articles" USING btree ("district_id","published_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE status = 'live';--> statement-breakpoint
CREATE INDEX "articles_category_feed_idx" ON "app"."articles" USING btree ("category_id","published_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE status = 'live';--> statement-breakpoint
CREATE INDEX "articles_search_idx" ON "app"."articles" USING gin ("search");--> statement-breakpoint
CREATE INDEX "articles_title_trgm_idx" ON "app"."articles" USING gin ("title" extensions.gin_trgm_ops);--> statement-breakpoint
CREATE INDEX "bookmarks_user_idx" ON "app"."bookmarks" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE INDEX "locations_parent_idx" ON "app"."locations" USING btree ("parent_id","level");--> statement-breakpoint
CREATE INDEX "locations_level_idx" ON "app"."locations" USING btree ("level");--> statement-breakpoint
CREATE INDEX "locations_name_trgm_idx" ON "app"."locations" USING gin ("name_en" extensions.gin_trgm_ops);--> statement-breakpoint
CREATE INDEX "profiles_role_idx" ON "app"."profiles" USING btree ("role");--> statement-breakpoint
CREATE INDEX "submission_events_submission_idx" ON "app"."submission_events" USING btree ("submission_id","created_at");--> statement-breakpoint
CREATE INDEX "submissions_status_idx" ON "app"."submissions" USING btree ("status","created_at");--> statement-breakpoint
CREATE INDEX "submissions_submitter_idx" ON "app"."submissions" USING btree ("submitter_id","created_at");