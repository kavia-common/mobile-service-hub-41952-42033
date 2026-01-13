import React from "react";
import { Link, Route, Routes } from "react-router-dom";
import { AuthPage } from "./pages/AuthPage";
import { Dashboard } from "./pages/Dashboard";
import { ServiceCentersPage } from "./pages/ServiceCentersPage";
import { TechniciansPage } from "./pages/TechniciansPage";
import { ServiceRequestsPage } from "./pages/ServiceRequestsPage";
import { InvoicesPage } from "./pages/InvoicesPage";
import { AuthProvider, useAuth } from "./auth/AuthContext";

function TopBar() {
  const { token, user, logout } = useAuth();
  return (
    <header className="topbar">
      <div className="brand">
        <Link to="/" className="brandLink">
          Mobile Service Hub
        </Link>
      </div>
      <nav className="nav">
        <Link to="/service-centers">Service Centers</Link>
        <Link to="/technicians">Technicians</Link>
        <Link to="/service-requests">Service Requests</Link>
        <Link to="/invoices">Invoices</Link>
      </nav>
      <div className="authBox">
        {token ? (
          <>
            <span className="muted">{user?.email} ({user?.role})</span>
            <button className="btn" onClick={logout}>Logout</button>
          </>
        ) : (
          <Link className="btn" to="/auth">Login</Link>
        )}
      </div>
    </header>
  );
}

export default function App() {
  return (
    <AuthProvider>
      <TopBar />
      <main className="container">
        <Routes>
          <Route path="/" element={<Dashboard />} />
          <Route path="/auth" element={<AuthPage />} />
          <Route path="/service-centers" element={<ServiceCentersPage />} />
          <Route path="/technicians" element={<TechniciansPage />} />
          <Route path="/service-requests" element={<ServiceRequestsPage />} />
          <Route path="/invoices" element={<InvoicesPage />} />
        </Routes>
      </main>
    </AuthProvider>
  );
}
