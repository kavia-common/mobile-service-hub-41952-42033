import React, { useEffect, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { apiFetch } from "../lib/api";

type ServiceRequest = {
  _id: string;
  customer_id: string;
  technician_id?: string;
  service_center_id?: string;
  status: string;
  description?: string;
  created_at?: string;
};

export function ServiceRequestsPage() {
  const { token, user } = useAuth();
  const [items, setItems] = useState<ServiceRequest[]>([]);
  const [description, setDescription] = useState("");
  const [serviceCenterId, setServiceCenterId] = useState("");
  const [technicianId, setTechnicianId] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    if (!token) return;
    setError(null);
    try {
      const res = await apiFetch<ServiceRequest[]>("/service-requests", { token });
      setItems(res);
    } catch (e: any) {
      setError(e.message);
    }
  }

  useEffect(() => {
    load();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [token]);

  async function create(e: React.FormEvent) {
    e.preventDefault();
    if (!token) return;
    setError(null);
    try {
      await apiFetch<ServiceRequest>("/service-requests", {
        method: "POST",
        token,
        body: JSON.stringify({
          description,
          service_center_id: serviceCenterId || undefined,
          technician_id: technicianId || undefined
        })
      });
      setDescription("");
      setServiceCenterId("");
      setTechnicianId("");
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  }

  return (
    <section className="grid">
      <div className="card">
        <h1>Service Requests</h1>
        <p className="muted">
          Customers see their own requests; admins see all.
        </p>
        {!token && <div className="hint">Login to view/create records.</div>}
        {error && <div className="error">{error}</div>}

        <table className="table">
          <thead>
            <tr>
              <th>Status</th>
              <th>Description</th>
              <th>Customer ID</th>
              <th>Service Center ID</th>
              <th>Technician ID</th>
            </tr>
          </thead>
          <tbody>
            {items.map((sr) => (
              <tr key={sr._id}>
                <td>{sr.status}</td>
                <td>{sr.description || "-"}</td>
                <td className="mono">{sr.customer_id}</td>
                <td className="mono">{sr.service_center_id || "-"}</td>
                <td className="mono">{sr.technician_id || "-"}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Create Service Request</h2>
        <div className="muted small">
          Logged in as: {user?.role || "Anonymous"}
        </div>
        <form className="form" onSubmit={create}>
          <label>
            Description
            <textarea value={description} onChange={(e) => setDescription(e.target.value)} />
          </label>
          <label>
            Service Center ID (optional)
            <input
              value={serviceCenterId}
              onChange={(e) => setServiceCenterId(e.target.value)}
            />
          </label>
          <label>
            Technician ID (optional)
            <input
              value={technicianId}
              onChange={(e) => setTechnicianId(e.target.value)}
            />
          </label>
          <button className="btn primary" disabled={!token}>
            Create
          </button>
        </form>
      </div>
    </section>
  );
}
