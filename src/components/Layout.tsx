import React from 'react';
import { Outlet, Link, useLocation } from 'react-router-dom';
import { useAuth } from '../contexts/AuthContext';
import {
  LayoutDashboard,
  Building2,
  Receipt,
  TrendingUp,
  Link as LinkIcon,
  LogOut,
} from 'lucide-react';

const navigation = [
  { name: 'Dashboard', href: '/', icon: LayoutDashboard },
  { name: 'Bank Accounts', href: '/bank-accounts', icon: Building2 },
  { name: 'Transactions', href: '/transactions', icon: Receipt },
  { name: 'Invoices', href: '/invoices', icon: Receipt },
  { name: 'Projections', href: '/projections', icon: TrendingUp },
  { name: 'Reconciliation', href: '/reconciliation', icon: LinkIcon },
];

export function Layout() {
  const { signOut, user } = useAuth();
  const location = useLocation();

  return (
    <div className="min-h-screen bg-gray-100">
      <div className="flex h-screen">
        {/* Sidebar */}
        <div className="w-64 bg-white shadow-lg">
          <div className="flex h-16 items-center justify-center border-b">
            <h1 className="text-xl font-bold text-gray-900">Cash Flow Manager</h1>
          </div>
          <nav className="mt-6">
            <div className="space-y-1 px-2">
              {navigation.map((item) => {
                const Icon = item.icon;
                return (
                  <Link
                    key={item.name}
                    to={item.href}
                    className={`
                      group flex items-center rounded-md px-2 py-2 text-sm font-medium
                      ${
                        location.pathname === item.href
                          ? 'bg-gray-100 text-gray-900'
                          : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                      }
                    `}
                  >
                    <Icon
                      className={`mr-3 h-5 w-5 flex-shrink-0
                        ${
                          location.pathname === item.href
                            ? 'text-gray-500'
                            : 'text-gray-400 group-hover:text-gray-500'
                        }
                      `}
                    />
                    {item.name}
                  </Link>
                );
              })}
            </div>
          </nav>
          <div className="absolute bottom-0 w-64 border-t p-4">
            <div className="flex items-center">
              <div className="flex-1">
                <p className="text-sm font-medium text-gray-900">{user?.email}</p>
              </div>
              <button
                onClick={() => signOut()}
                className="ml-2 rounded-md p-2 text-gray-400 hover:bg-gray-100 hover:text-gray-500"
              >
                <LogOut className="h-5 w-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Main content */}
        <main className="flex-1 overflow-y-auto p-8">
          <Outlet />
        </main>
      </div>
    </div>
  );
}