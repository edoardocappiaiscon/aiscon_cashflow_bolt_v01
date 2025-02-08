import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { Layout } from './components/Layout';
import { Dashboard } from './pages/Dashboard';
import { BankAccounts } from './pages/BankAccounts';
import { Transactions } from './pages/Transactions';
import { Invoices } from './pages/Invoices';
import { Projections } from './pages/Projections';
import { Reconciliation } from './pages/Reconciliation';
import { Login } from './pages/Login';
import { AuthProvider, useAuth } from './contexts/AuthContext';

const ProtectedRoute = ({ children }: { children: React.ReactNode }) => {
  const { session } = useAuth();
  if (!session) {
    return <Navigate to="/login" replace />;
  }
  return <>{children}</>;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <Routes>
          <Route path="/login" element={<Login />} />
          <Route
            path="/"
            element={
              <ProtectedRoute>
                <Layout />
              </ProtectedRoute>
            }
          >
            <Route index element={<Dashboard />} />
            <Route path="bank-accounts" element={<BankAccounts />} />
            <Route path="transactions" element={<Transactions />} />
            <Route path="invoices" element={<Invoices />} />
            <Route path="projections" element={<Projections />} />
            <Route path="reconciliation" element={<Reconciliation />} />
          </Route>
        </Routes>
      </Router>
    </AuthProvider>
  );
}

export default App;