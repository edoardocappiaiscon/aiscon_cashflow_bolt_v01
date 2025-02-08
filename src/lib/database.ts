import { supabase } from './supabase';
import { PostgrestError } from '@supabase/supabase-js';

export interface BankAccount {
  id: string;
  name: string;
  account_number: string;
  type: 'checking' | 'savings' | 'credit_card';
  balance?: number;
  created_at: string;
}

export interface Transaction {
  id: string;
  account_id: string;
  date: string;
  amount: number;
  description: string;
  category: string;
  reconciled: boolean;
  created_at: string;
}

export interface Invoice {
  id: string;
  type: 'sales' | 'purchase';
  number: string;
  date: string;
  due_date: string;
  amount: number;
  status: 'draft' | 'pending' | 'paid' | 'cancelled';
  counterparty: string;
  description?: string;
  reconciled: boolean;
  created_at: string;
}

export interface CashProjection {
  id: string;
  date: string;
  amount: number;
  category: string;
  description?: string;
  probability: number;
  created_at: string;
}

export interface DatabaseError {
  error: PostgrestError;
}

export const db = {
  bankAccounts: {
    async getAll(): Promise<BankAccount[] | DatabaseError> {
      const { data, error } = await supabase
        .from('bank_accounts')
        .select('*')
        .order('name');
      
      if (error) return { error };
      return data;
    }
  },

  transactions: {
    async getAll(): Promise<Transaction[] | DatabaseError> {
      const { data, error } = await supabase
        .from('bank_transactions')
        .select('*')
        .order('date', { ascending: false });
      
      if (error) return { error };
      return data;
    }
  },

  invoices: {
    async getAll(filter?: 'sales' | 'purchase'): Promise<Invoice[] | DatabaseError> {
      let query = supabase
        .from('invoices')
        .select('*')
        .order('date', { ascending: false });
      
      if (filter) {
        query = query.eq('type', filter);
      }
      
      const { data, error } = await query;
      if (error) return { error };
      return data;
    }
  },

  projections: {
    async getAll(): Promise<CashProjection[] | DatabaseError> {
      const { data, error } = await supabase
        .from('cash_projections')
        .select('*')
        .order('date');
      
      if (error) return { error };
      return data;
    }
  }
};