import React from "react";
import { Link } from "react-router-dom";

export function Dashboard() {
  return (
    <section className="card">
      <h1>Dashboard</h1>
      <p className="muted">
        Minimal admin/customer UI to create and view core records. Use the Login/Register page to obtain a token.
      </p>
      <ul>
        <li><Link to="/service-centers">Service Centers</Link></li>
        <li><Link to="/technicians">Technicians</Link></li>
        <li><Link to="/service-requests">Service Requests</Link></li>
        <li><Link to="/invoices">Invoices</Link></li>
      </ul>
    </section>
  );
}
