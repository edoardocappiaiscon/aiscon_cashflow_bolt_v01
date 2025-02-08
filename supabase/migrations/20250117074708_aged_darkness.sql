/*
  # Initial Schema for Cash Flow Management System

  1. New Tables
    - `users_roles` - User role assignments
      - `id` (uuid, primary key)
      - `user_id` (uuid, references auth.users)
      - `role` (text)
      - `created_at` (timestamp)
    
    - `bank_accounts` - Bank account details
      - `id` (uuid, primary key)
      - `name` (text)
      - `account_number` (text)
      - `type` (text)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
    
    - `bank_transactions` - Bank transactions
      - `id` (uuid, primary key)
      - `account_id` (uuid, references bank_accounts)
      - `date` (date)
      - `amount` (decimal)
      - `description` (text)
      - `category` (text)
      - `reconciled` (boolean)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
    
    - `invoices` - Sales and purchase invoices
      - `id` (uuid, primary key)
      - `type` (text) - 'sales' or 'purchase'
      - `number` (text)
      - `date` (date)
      - `due_date` (date)
      - `amount` (decimal)
      - `status` (text)
      - `counterparty` (text)
      - `description` (text)
      - `reconciled` (boolean)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
    
    - `cash_projections` - Future cash flow projections
      - `id` (uuid, primary key)
      - `date` (date)
      - `amount` (decimal)
      - `category` (text)
      - `description` (text)
      - `probability` (decimal)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)
    
    - `reconciliations` - Links between transactions and invoices
      - `id` (uuid, primary key)
      - `transaction_id` (uuid, references bank_transactions)
      - `invoice_id` (uuid, references invoices)
      - `amount` (decimal)
      - `created_at` (timestamp)
      - `created_by` (uuid, references auth.users)

  2. Security
    - Enable RLS on all tables
    - Add policies for role-based access control
    - Users can only access data they created or have permission to view based on their role
*/

-- Create enum types
CREATE TYPE user_role AS ENUM ('admin', 'manager', 'user');
CREATE TYPE account_type AS ENUM ('checking', 'savings', 'credit_card');
CREATE TYPE invoice_type AS ENUM ('sales', 'purchase');
CREATE TYPE invoice_status AS ENUM ('draft', 'pending', 'paid', 'cancelled');

-- Users roles table
CREATE TABLE users_roles (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id uuid REFERENCES auth.users NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    created_at timestamptz DEFAULT now(),
    UNIQUE(user_id)
);

-- Bank accounts table
CREATE TABLE bank_accounts (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    account_number text NOT NULL,
    type account_type NOT NULL,
    created_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users NOT NULL
);

-- Bank transactions table
CREATE TABLE bank_transactions (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    account_id uuid REFERENCES bank_accounts NOT NULL,
    date date NOT NULL,
    amount decimal(15,2) NOT NULL,
    description text,
    category text,
    reconciled boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users NOT NULL
);

-- Invoices table
CREATE TABLE invoices (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    type invoice_type NOT NULL,
    number text NOT NULL,
    date date NOT NULL,
    due_date date NOT NULL,
    amount decimal(15,2) NOT NULL,
    status invoice_status NOT NULL DEFAULT 'pending',
    counterparty text NOT NULL,
    description text,
    reconciled boolean DEFAULT false,
    created_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users NOT NULL
);

-- Cash projections table
CREATE TABLE cash_projections (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    date date NOT NULL,
    amount decimal(15,2) NOT NULL,
    category text NOT NULL,
    description text,
    probability decimal(3,2) DEFAULT 1.00,
    created_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users NOT NULL
);

-- Reconciliations table
CREATE TABLE reconciliations (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id uuid REFERENCES bank_transactions,
    invoice_id uuid REFERENCES invoices,
    amount decimal(15,2) NOT NULL,
    created_at timestamptz DEFAULT now(),
    created_by uuid REFERENCES auth.users NOT NULL
);

-- Enable Row Level Security
ALTER TABLE users_roles ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE bank_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE invoices ENABLE ROW LEVEL SECURITY;
ALTER TABLE cash_projections ENABLE ROW LEVEL SECURITY;
ALTER TABLE reconciliations ENABLE ROW LEVEL SECURITY;

-- Create policies
-- Users roles policies
CREATE POLICY "Admins can manage all roles"
    ON users_roles
    TO authenticated
    USING (EXISTS (
        SELECT 1 FROM users_roles WHERE user_id = auth.uid() AND role = 'admin'
    ));

CREATE POLICY "Users can view their own role"
    ON users_roles
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid());

-- Bank accounts policies
CREATE POLICY "Users can view bank accounts"
    ON bank_accounts
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins and managers can manage bank accounts"
    ON bank_accounts
    USING (EXISTS (
        SELECT 1 FROM users_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'manager')
    ));

-- Bank transactions policies
CREATE POLICY "Users can view transactions"
    ON bank_transactions
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins and managers can manage transactions"
    ON bank_transactions
    USING (EXISTS (
        SELECT 1 FROM users_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'manager')
    ));

-- Invoices policies
CREATE POLICY "Users can view invoices"
    ON invoices
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins and managers can manage invoices"
    ON invoices
    USING (EXISTS (
        SELECT 1 FROM users_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'manager')
    ));

-- Cash projections policies
CREATE POLICY "Users can view projections"
    ON cash_projections
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins and managers can manage projections"
    ON cash_projections
    USING (EXISTS (
        SELECT 1 FROM users_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'manager')
    ));

-- Reconciliations policies
CREATE POLICY "Users can view reconciliations"
    ON reconciliations
    FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Only admins and managers can manage reconciliations"
    ON reconciliations
    USING (EXISTS (
        SELECT 1 FROM users_roles 
        WHERE user_id = auth.uid() 
        AND role IN ('admin', 'manager')
    ));