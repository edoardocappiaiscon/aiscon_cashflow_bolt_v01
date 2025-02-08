import React, { useEffect, useState } from 'react';
import { Plus } from 'lucide-react';
import { db, BankAccount, DatabaseError } from '../lib/database';

export function BankAccounts() {
  const [accounts, setAccounts] = useState<BankAccount[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function loadAccounts() {
      const result = await db.bankAccounts.getAll();
      if ('error' in result) {
        setError(result.error.message);
      } else {
        setAccounts(result);
      }
    }
    loadAccounts();
  }, []);

  if (error) {
    return (
      <div className="p-4 text-red-600 bg-red-50 rounded-md">
        Error loading accounts: {error}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-semibold text-gray-900">Bank Accounts</h1>
        <button className="inline-flex items-center px-4 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
          <Plus className="h-5 w-5 mr-2" />
          Add Account
        </button>
      </div>

      <div className="bg-white shadow overflow-hidden sm:rounded-md">
        <ul className="divide-y divide-gray-200">
          {accounts.map((account) => (
            <li key={account.id}>
              <div className="px-4 py-4 sm:px-6">
                <div className="flex items-center justify-between">
                  <div className="flex flex-col">
                    <p className="text-sm font-medium text-indigo-600 truncate">
                      {account.name}
                    </p>
                    <p className="mt-1 text-sm text-gray-500">
                      Account Number: {account.account_number.replace(/(\d{4})$/, '****$1')}
                    </p>
                  </div>
                  <div className="flex flex-col items-end">
                    <p className={`text-sm font-semibold ${account.balance && account.balance >= 0 ? 'text-green-600' : 'text-red-600'}`}>
                      €{account.balance?.toLocaleString('it-IT', { minimumFractionDigits: 2 })}
                    </p>
                    <p className="mt-1 text-sm text-gray-500 capitalize">
                      {account.type.replace('_', ' ')}
                    </p>
                  </div>
                </div>
              </div>
            </li>
          ))}
        </ul>
      </div>
    </div>
  );
}