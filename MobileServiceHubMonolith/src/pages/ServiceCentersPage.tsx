import React, { useEffect, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { apiFetch } from "../lib/api";

type ServiceCenter = {
  _id: string;
  name: string;
  address?: string;
  admin_id: string;
};

export function ServiceCentersPage() {
  const { token } = useAuth();
  const [items, setItems] = useState<ServiceCenter[]>([]);
  const [name, setName] = useState("");
  const [address, setAddress] = useState("");
  const [adminId, setAdminId] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    if (!token) return;
    setError(null);
    try {
      const res = await apiFetch<ServiceCenter[]>("/service-centers", { token });
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
      await apiFetch<ServiceCenter>("/service-centers", {
        method: "POST",
        token,
        body: JSON.stringify({ name, address, admin_id: adminId })
      });
      setName("");
      setAddress("");
      setAdminId("");
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  }

  return (
    <section className="grid">
      <div className="card">
        <h1>Service Centers</h1>
        <p className="muted">Create requires SuperAdmin.</p>
        {!token && <div className="hint">Login to view/create records.</div>}
        {error && <div className="error">{error}</div>}
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Address</th>
              <th>Admin User ID</th>
            </tr>
          </thead>
          <tbody>
            {items.map((sc) => (
              <tr key={sc._id}>
                <td>{sc.name}</td>
                <td>{sc.address || "-"}</td>
                <td className="mono">{sc.admin_id}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Create Service Center</h2>
        <form className="form" onSubmit={create}>
          <label>
            Name
            <input value={name} onChange={(e) => setName(e.target.value)} />
          </label>
          <label>
            Address
            <input value={address} onChange={(e) => setAddress(e.target.value)} />
          </label>
          <label>
            Admin User ID
            <input value={adminId} onChange={(e) => setAdminId(e.target.value)} />
          </label>
          <button className="btn primary" disabled={!token}>
            Create
          </button>
        </form>
      </div>
    </section>
  );
}
