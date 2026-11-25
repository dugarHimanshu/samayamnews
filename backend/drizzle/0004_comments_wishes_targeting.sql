CREATE TYPE "app"."ad_target_scope" AS ENUM('all', 'state', 'district');--> statement-breakpoint
CREATE TYPE "app"."wish_kind" AS ENUM('birthday', 'anniversary');--> statement-breakpoint
CREATE TABLE "app"."comments" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"article_id" uuid NOT NULL,
	"user_id" uuid NOT NULL,
	"body" text NOT NULL,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"deleted_at" timestamp with time zone,
	"deleted_by" uuid
);
--> statement-breakpoint
CREATE TABLE "app"."wishes" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"kind" "app"."wish_kind" NOT NULL,
	"photo_media_id" uuid,
	"recipient_name" text NOT NULL,
	"message" text NOT NULL,
	"from_names" text NOT NULL,
	"district_id" integer,
	"status" "app"."application_status" DEFAULT 'pending' NOT NULL,
	"submitted_by" uuid NOT NULL,
	"reviewed_by" uuid,
	"reviewed_at" timestamp with time zone,
	"rejection_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "slides" jsonb;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "schedule_type" text;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "category" text;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "target_scope" "app"."ad_target_scope" DEFAULT 'all' NOT NULL;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "target_state_id" integer;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD COLUMN "target_district_id" integer;--> statement-breakpoint
ALTER TABLE "app"."article_stats" ADD COLUMN "comments" bigint DEFAULT 0 NOT NULL;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD COLUMN "related_article_id" uuid;--> statement-breakpoint
ALTER TABLE "app"."articles" ADD COLUMN "related_anchor" text;--> statement-breakpoint
ALTER TABLE "app"."profiles" ADD COLUMN "disabled_at" timestamp with time zone;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD COLUMN "related_article_id" uuid;--> statement-breakpoint
ALTER TABLE "app"."submissions" ADD COLUMN "related_anchor" text;--> statement-breakpoint
ALTER TABLE "app"."comments" ADD CONSTRAINT "comments_article_id_articles_id_fk" FOREIGN KEY ("article_id") REFERENCES "app"."articles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."comments" ADD CONSTRAINT "comments_user_id_profiles_id_fk" FOREIGN KEY ("user_id") REFERENCES "app"."profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."comments" ADD CONSTRAINT "comments_deleted_by_profiles_id_fk" FOREIGN KEY ("deleted_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."wishes" ADD CONSTRAINT "wishes_photo_media_id_media_id_fk" FOREIGN KEY ("photo_media_id") REFERENCES "app"."media"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."wishes" ADD CONSTRAINT "wishes_district_id_locations_id_fk" FOREIGN KEY ("district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."wishes" ADD CONSTRAINT "wishes_submitted_by_profiles_id_fk" FOREIGN KEY ("submitted_by") REFERENCES "app"."profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."wishes" ADD CONSTRAINT "wishes_reviewed_by_profiles_id_fk" FOREIGN KEY ("reviewed_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "comments_article_idx" ON "app"."comments" USING btree ("article_id","created_at" DESC NULLS LAST,"id" DESC NULLS LAST) WHERE deleted_at IS NULL;--> statement-breakpoint
CREATE INDEX "wishes_status_idx" ON "app"."wishes" USING btree ("status","created_at" DESC NULLS LAST);--> statement-breakpoint
ALTER TABLE "app"."ads" ADD CONSTRAINT "ads_target_state_id_locations_id_fk" FOREIGN KEY ("target_state_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."ads" ADD CONSTRAINT "ads_target_district_id_locations_id_fk" FOREIGN KEY ("target_district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;