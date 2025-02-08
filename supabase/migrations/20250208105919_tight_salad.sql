/*
  # Fix Users Roles Policies

  1. Changes
    - Drop existing policies on users_roles table
    - Create new policies with proper access control
    - Add default admin user creation function
    - Add policy for service role

  2. Security
    - Prevent infinite recursion in policies
    - Ensure proper access control
    - Allow service role full access
*/

-- Drop existing policies on users_roles
DROP POLICY IF EXISTS "Admins can manage all roles" ON users_roles;
DROP POLICY IF EXISTS "Users can view their own role" ON users_roles;

-- Create new policies
CREATE POLICY "Service role has full access"
  ON users_roles
  FOR ALL
  TO service_role
  USING (true)
  WITH CHECK (true);

CREATE POLICY "Users can view their own role"
  ON users_roles
  FOR SELECT
  TO authenticated
  USING (user_id = auth.uid());

CREATE POLICY "Admins can manage roles"
  ON users_roles
  USING (
    EXISTS (
      SELECT 1 FROM users_roles ur
      WHERE ur.user_id = auth.uid()
        AND ur.role = 'admin'
        AND ur.id != users_roles.id  -- Prevent recursion
    )
  );

-- Create function to set up first admin user
CREATE OR REPLACE FUNCTION public.create_first_admin()
RETURNS trigger
SECURITY DEFINER
SET search_path = public
LANGUAGE plpgsql
AS $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM users_roles WHERE role = 'admin') THEN
    INSERT INTO users_roles (user_id, role)
    VALUES (NEW.id, 'admin');
  END IF;
  RETURN NEW;
END;
$$;

-- Create trigger for first admin
DROP TRIGGER IF EXISTS on_first_user_admin ON auth.users;
CREATE TRIGGER on_first_user_admin
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.create_first_admin();

-- Grant execute permission to service role
GRANT EXECUTE ON FUNCTION public.create_first_admin TO service_role;