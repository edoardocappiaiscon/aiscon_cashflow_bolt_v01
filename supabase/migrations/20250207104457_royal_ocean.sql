/*
  # Fix user sync functionality

  1. Changes
    - Remove email column reference as it's not in the users table
    - Fix PERFORM syntax in handle_user_login
    - Add INSERT permission to users table
*/

-- Drop existing functions to recreate them
DROP FUNCTION IF EXISTS public.sync_user_data() CASCADE;
DROP FUNCTION IF EXISTS public.handle_user_login() CASCADE;

-- Create function to sync user data
CREATE OR REPLACE FUNCTION public.sync_user_data()
RETURNS trigger AS $$
BEGIN
  -- Check if user exists in public.users
  IF NOT EXISTS (SELECT 1 FROM public.users WHERE id = new.id) THEN
    -- Insert new user if they don't exist
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
    -- Update existing user
    UPDATE public.users
    SET
      full_name = COALESCE(new.raw_user_meta_data->>'full_name', users.full_name),
      updated_at = now()
    WHERE id = new.id;
  END IF;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update handle_user_login to include sync
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS trigger AS $$
DECLARE
  _dummy record;
BEGIN
  -- First sync the user data
  SELECT * INTO _dummy FROM public.sync_user_data(new);
  
  -- Then update the last login timestamp
  UPDATE public.users
  SET last_login = now()
  WHERE id = new.id;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for user data sync
DROP TRIGGER IF EXISTS on_auth_user_updated ON auth.users;
CREATE TRIGGER on_auth_user_updated
  AFTER UPDATE ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.sync_user_data();

-- Create trigger for user login
DROP TRIGGER IF EXISTS on_auth_user_login ON auth.users;
CREATE TRIGGER on_auth_user_login
  AFTER UPDATE OF last_sign_in_at ON auth.users
  FOR EACH ROW
  WHEN (OLD.last_sign_in_at IS DISTINCT FROM NEW.last_sign_in_at)
  EXECUTE FUNCTION public.handle_user_login();

-- Add INSERT policy for the trigger function
CREATE POLICY "Triggers can insert users"
  ON users
  FOR INSERT
  TO authenticated
  WITH CHECK (true);

-- Add UPDATE policy for the trigger function
CREATE POLICY "Triggers can update users"
  ON users
  FOR UPDATE
  TO authenticated
  USING (true)
  WITH CHECK (true);