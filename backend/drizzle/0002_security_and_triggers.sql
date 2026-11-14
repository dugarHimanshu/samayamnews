-- 1) Lock the app schema away from Supabase's client-facing roles.
--    The Flutter app must go through our API; the publishable key alone can read/write nothing here.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'anon') THEN
    EXECUTE 'REVOKE ALL ON SCHEMA app FROM anon, authenticated';
    EXECUTE 'REVOKE ALL ON ALL TABLES IN SCHEMA app FROM anon, authenticated';
    EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA app REVOKE ALL ON TABLES FROM anon, authenticated';
  END IF;
END $$;
--> statement-breakpoint

-- 2) profiles.id must be a real Supabase Auth user (only when the auth schema exists, i.e. on Supabase).
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    EXECUTE 'ALTER TABLE app.profiles ADD CONSTRAINT profiles_auth_user_fk FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE';
  END IF;
END $$;
--> statement-breakpoint

-- 3) Keep updated_at honest.
CREATE OR REPLACE FUNCTION app.touch_updated_at() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END $$;
--> statement-breakpoint
CREATE TRIGGER profiles_touch BEFORE UPDATE ON app.profiles FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();
--> statement-breakpoint
CREATE TRIGGER submissions_touch BEFORE UPDATE ON app.submissions FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();
--> statement-breakpoint
CREATE TRIGGER articles_touch BEFORE UPDATE ON app.articles FOR EACH ROW EXECUTE FUNCTION app.touch_updated_at();
--> statement-breakpoint

-- 4) Every new Supabase Auth user automatically gets a reader profile.
CREATE OR REPLACE FUNCTION app.handle_new_auth_user() RETURNS trigger
LANGUAGE plpgsql SECURITY DEFINER SET search_path = '' AS $$
BEGIN
  INSERT INTO app.profiles (id, email, full_name)
  VALUES (NEW.id, NEW.email, NEW.raw_user_meta_data ->> 'full_name')
  ON CONFLICT (id) DO NOTHING;
  RETURN NEW;
END $$;
--> statement-breakpoint
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_schema = 'auth' AND table_name = 'users') THEN
    EXECUTE 'DROP TRIGGER IF EXISTS on_auth_user_created_app_profile ON auth.users';
    EXECUTE 'CREATE TRIGGER on_auth_user_created_app_profile AFTER INSERT ON auth.users FOR EACH ROW EXECUTE FUNCTION app.handle_new_auth_user()';
  END IF;
END $$;
