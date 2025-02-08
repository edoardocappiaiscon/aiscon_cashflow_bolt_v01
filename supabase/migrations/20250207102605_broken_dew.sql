/*
  # Add user sync functionality

  1. Functions
    - Add function to sync user data from auth.users to public.users
    - Update handle_user_login to use the sync function

  2. Changes
    - Modify existing handle_user_login function to sync user data
*/

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
      email,
      created_at,
      updated_at
    ) VALUES (
      new.id,
      new.raw_user_meta_data->>'full_name',
      new.email,
      new.created_at,
      new.updated_at
    );
  ELSE
    -- Update existing user
    UPDATE public.users
    SET
      full_name = COALESCE(new.raw_user_meta_data->>'full_name', users.full_name),
      email = COALESCE(new.email, users.email),
      updated_at = now()
    WHERE id = new.id;
  END IF;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Update handle_user_login to include sync
CREATE OR REPLACE FUNCTION public.handle_user_login()
RETURNS trigger AS $$
BEGIN
  -- First sync the user data
  PERFORM public.sync_user_data(new);
  
  -- Then update the last login timestamp
  UPDATE public.users
  SET last_login = now()
  WHERE id = new.id;
  
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger for user data sync if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger 
    WHERE tgname = 'on_auth_user_updated'
  ) THEN
    CREATE TRIGGER on_auth_user_updated
      AFTER UPDATE ON auth.users
      FOR EACH ROW
      EXECUTE FUNCTION public.sync_user_data();
  END IF;
END $$;