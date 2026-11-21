CREATE TYPE "app"."application_status" AS ENUM('pending', 'approved', 'rejected');--> statement-breakpoint
ALTER TYPE "app"."media_kind" ADD VALUE 'video';--> statement-breakpoint
CREATE TABLE "app"."contributor_applications" (
	"id" uuid PRIMARY KEY DEFAULT gen_random_uuid() NOT NULL,
	"user_id" uuid NOT NULL,
	"requested_role" "app"."role" NOT NULL,
	"full_name" text NOT NULL,
	"mobile" text NOT NULL,
	"email" text NOT NULL,
	"address" text,
	"state_id" integer,
	"district_id" integer NOT NULL,
	"mandal_id" integer,
	"status" "app"."application_status" DEFAULT 'pending' NOT NULL,
	"reviewed_by" uuid,
	"reviewed_at" timestamp with time zone,
	"rejection_reason" text,
	"created_at" timestamp with time zone DEFAULT now() NOT NULL,
	"updated_at" timestamp with time zone DEFAULT now() NOT NULL
);
--> statement-breakpoint
ALTER TABLE "app"."contributor_applications" ADD CONSTRAINT "contributor_applications_user_id_profiles_id_fk" FOREIGN KEY ("user_id") REFERENCES "app"."profiles"("id") ON DELETE cascade ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."contributor_applications" ADD CONSTRAINT "contributor_applications_state_id_locations_id_fk" FOREIGN KEY ("state_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."contributor_applications" ADD CONSTRAINT "contributor_applications_district_id_locations_id_fk" FOREIGN KEY ("district_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."contributor_applications" ADD CONSTRAINT "contributor_applications_mandal_id_locations_id_fk" FOREIGN KEY ("mandal_id") REFERENCES "app"."locations"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
ALTER TABLE "app"."contributor_applications" ADD CONSTRAINT "contributor_applications_reviewed_by_profiles_id_fk" FOREIGN KEY ("reviewed_by") REFERENCES "app"."profiles"("id") ON DELETE no action ON UPDATE no action;--> statement-breakpoint
CREATE INDEX "contributor_applications_status_idx" ON "app"."contributor_applications" USING btree ("status","created_at");--> statement-breakpoint
CREATE INDEX "contributor_applications_user_idx" ON "app"."contributor_applications" USING btree ("user_id","created_at");--> statement-breakpoint
CREATE UNIQUE INDEX "contributor_applications_one_pending" ON "app"."contributor_applications" USING btree ("user_id") WHERE status = 'pending';--> statement-breakpoint
CREATE TRIGGER contributor_applications_touch BEFORE UPDATE ON app.contributor_applications FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();
