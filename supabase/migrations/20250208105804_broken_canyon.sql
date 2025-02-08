/*
  # Add sample data function and trigger

  1. New Function
    - Creates a function to insert sample data for a new user
    - Handles bank accounts, transactions, invoices, and projections
    - Uses the user's ID for all created_by fields

  2. Trigger
    - Automatically adds sample data when a new user is created
    - Only runs once per user

  3. Security
    - Function runs with SECURITY DEFINER to ensure proper permissions
    - Checks if sample data already exists for the user
*/

-- Create function to generate sample data for a user
CREATE OR REPLACE FUNCTION public.generate_sample_data(user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  checking_account_id uuid;
  savings_account_id uuid;
  credit_card_id uuid;
  current_date date;
  random_amount decimal;
  random_date date;
BEGIN
  -- Only proceed if the user doesn't have any bank accounts yet
  IF NOT EXISTS (SELECT 1 FROM bank_accounts WHERE created_by = user_id) THEN
    -- Insert bank accounts
    INSERT INTO bank_accounts (name, account_number, type, created_at, created_by)
    VALUES
      ('Main Checking', '1234567890', 'checking', now() - interval '6 months', user_id),
      ('Business Savings', '9876543210', 'savings', now() - interval '6 months', user_id),
      ('Corporate Card', '4567890123', 'credit_card', now() - interval '6 months', user_id)
    RETURNING id INTO checking_account_id;

    -- Get the account IDs
    SELECT id INTO savings_account_id FROM bank_accounts 
    WHERE created_by = user_id AND type = 'savings';
    SELECT id INTO credit_card_id FROM bank_accounts 
    WHERE created_by = user_id AND type = 'credit_card';

    -- Insert transactions for each account
    FOR current_date IN 
      SELECT generate_series(
        (now() - interval '5 months')::date,
        now()::date,
        '5 days'::interval
      )
    LOOP
      -- Random amount between -2000 and 5000
      random_amount := CASE 
        WHEN random() > 0.7 THEN random() * 5000 + 1000
        ELSE random() * -2000 - 100
      END;

      INSERT INTO bank_transactions (
        account_id,
        date,
        amount,
        description,
        category,
        created_by
      ) VALUES (
        CASE floor(random() * 3)::int
          WHEN 0 THEN checking_account_id
          WHEN 1 THEN savings_account_id
          ELSE credit_card_id
        END,
        current_date,
        random_amount,
        CASE 
          WHEN random_amount > 0 THEN (
            ARRAY['Client Payment', 'Consulting Fee', 'Service Revenue', 'Product Sale']
          )[floor(random() * 4 + 1)]
          ELSE (
            ARRAY['Office Supplies', 'Software License', 'Marketing', 'Travel Expense']
          )[floor(random() * 4 + 1)]
        END,
        CASE WHEN random_amount > 0 THEN 'Income' ELSE 'Expense' END,
        user_id
      );
    END LOOP;

    -- Insert invoices
    FOR i IN 1..20 LOOP
      random_date := (now() - (random() * 150 || ' days')::interval)::date;
      
      INSERT INTO invoices (
        type,
        number,
        date,
        due_date,
        amount,
        status,
        counterparty,
        description,
        created_by
      ) VALUES (
        CASE WHEN random() > 0.5 THEN 'sales' ELSE 'purchase' END,
        CASE 
          WHEN type = 'sales' THEN 'INV-' || LPAD(i::text, 3, '0')
          ELSE 'BILL-' || LPAD(i::text, 3, '0')
        END,
        random_date,
        random_date + interval '30 days',
        CASE 
          WHEN type = 'sales' THEN random() * 5000 + 1000
          ELSE random() * 2000 + 500
        END,
        (ARRAY['draft', 'pending', 'paid', 'cancelled'])[floor(random() * 3 + 1)],
        CASE 
          WHEN type = 'sales' THEN 'Client ' || chr(floor(random() * 26 + 65)::int)
          ELSE 'Supplier ' || chr(floor(random() * 26 + 65)::int)
        END,
        CASE 
          WHEN type = 'sales' THEN 'Professional Services'
          ELSE 'Operating Expenses'
        END,
        user_id
      );
    END LOOP;

    -- Insert projections
    FOR i IN 1..6 LOOP
      INSERT INTO cash_projections (
        date,
        amount,
        category,
        description,
        probability,
        created_by
      ) VALUES (
        (now() + (i * 30 || ' days')::interval)::date,
        CASE 
          WHEN random() > 0.3 THEN random() * 10000 + 5000
          ELSE random() * -3000 - 1000
        END,
        CASE 
          WHEN amount > 0 THEN (
            ARRAY['Sales Revenue', 'Consulting Income', 'Investment Return']
          )[floor(random() * 3 + 1)]
          ELSE (
            ARRAY['Operating Expenses', 'Tax Payment', 'Equipment Purchase']
          )[floor(random() * 3 + 1)]
        END,
        CASE 
          WHEN amount > 0 THEN 'Projected ' || category
          ELSE 'Expected ' || category
        END,
        random() * 0.5 + 0.5,
        user_id
      );
    END LOOP;
  END IF;
END;
$$;

-- Create trigger to generate sample data for new users
CREATE OR REPLACE FUNCTION public.handle_new_user_sample_data()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.generate_sample_data(new.id);
  RETURN new;
END;
$$;

-- Add trigger to auth.users table
DROP TRIGGER IF EXISTS on_auth_user_created_sample_data ON auth.users;
CREATE TRIGGER on_auth_user_created_sample_data
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_new_user_sample_data();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION public.generate_sample_data TO service_role;
GRANT EXECUTE ON FUNCTION public.handle_new_user_sample_data TO service_role;