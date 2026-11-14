-- Extensions and the private application schema.
-- On Supabase the `extensions` schema already exists; on plain Postgres we create it.
CREATE SCHEMA IF NOT EXISTS extensions;
--> statement-breakpoint
CREATE EXTENSION IF NOT EXISTS pg_trgm WITH SCHEMA extensions;
