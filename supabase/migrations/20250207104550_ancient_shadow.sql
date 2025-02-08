/*
  # Fix authentication and permissions

  1. Changes
    - Add proper security definer settings for functions
    - Add explicit grants for auth schema access
    - Fix trigger permissions
    - Add policy for system level operations
*/

-- Revoke and regrant necessary permissions
REVOKE ALL ON public.users FROM anon, authenticated;
GRANT ALL ON public.users TO service_role;
GRANT SELECT, UPDATE ON public.users TO authenticated;

-- Drop existing functions and triggers to recreate them with proper permissions
DROP FUNCTION IF EXISTS public.sync_user_data() CASCADE;
DROP FUNCTION IF EXISTS public.handle_new_user() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_login() CASCADE;

-- Create function to handle new user creation with proper security context
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  INSERT INTO public.users (id)
  VALUES (new.id);
  RETURN new;
END;
$$;

-- Create function to sync user data with proper security context
CREATE OR REPLACE FUNCTION public.sync_user_data()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = new.id) THEN
    INSERT INTO public.users (
      id,
      full_name,
      created_at,
      updated_at
    ) VALUES (
      new.id,
      new.raw_user_meta_data->>'full_name',
      new.created_at,
      new.updated_at
    );
  ELSE
    UPDATE public.users
    SET
      full_name = COALESCE(new.raw_user_meta_data->>'full_name', users.full_name),
      updated_at = now()
    WHERE id = new.id;
  END IF;
  
  RETURN new;
END;
$$;

-- Create function to handle user login with proper security context
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.users
  SET last_login = now()
  WHERE id = new.id;
  
  RETURN new;
END;
$$;

-- Grant execute permissions on functions
GRANT EXECUTE ON FUNCTION public.handle_new_user() TO service_role;
GRANT EXECUTE ON FUNCTION public.sync_user_data() TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_user_login() TO service_role;

-- Recreate triggers
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user();

DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_data();

DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.handle_user_login();

-- Add system-level operations policy
CREATE POLICY "System functions can perform all operations"
  ON public.users
  TO service_role
  USING (true)
  WITH CHECK (true);