import React, { useEffect, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { apiFetch } from "../lib/api";

type Technician = {
  _id: string;
  name: string;
  skills: string[];
  availability: string;
  service_center_id: string;
  is_active: boolean;
};

export function TechniciansPage() {
  const { token } = useAuth();
  const [items, setItems] = useState<Technician[]>([]);
  const [name, setName] = useState("");
  const [skills, setSkills] = useState("");
  const [availability, setAvailability] = useState("Available");
  const [serviceCenterId, setServiceCenterId] = useState("");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    if (!token) return;
    setError(null);
    try {
      const res = await apiFetch<Technician[]>("/technicians", { token });
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
      await apiFetch<Technician>("/technicians", {
        method: "POST",
        token,
        body: JSON.stringify({
          name,
          skills: skills
            .split(",")
            .map((s) => s.trim())
            .filter(Boolean),
          availability,
          service_center_id: serviceCenterId
        })
      });
      setName("");
      setSkills("");
      setAvailability("Available");
      setServiceCenterId("");
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  }

  return (
    <section className="grid">
      <div className="card">
        <h1>Technicians</h1>
        {!token && <div className="hint">Login to view/create records.</div>}
        {error && <div className="error">{error}</div>}
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Skills</th>
              <th>Availability</th>
              <th>Service Center ID</th>
            </tr>
          </thead>
          <tbody>
            {items.map((t) => (
              <tr key={t._id}>
                <td>{t.name}</td>
                <td>{t.skills?.join(", ") || "-"}</td>
                <td>{t.availability}</td>
                <td className="mono">{t.service_center_id}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Create Technician</h2>
        <form className="form" onSubmit={create}>
          <label>
            Name
            <input value={name} onChange={(e) => setName(e.target.value)} />
          </label>
          <label>
            Skills (comma-separated)
            <input value={skills} onChange={(e) => setSkills(e.target.value)} />
          </label>
          <label>
            Availability
            <input value={availability} onChange={(e) => setAvailability(e.target.value)} />
          </label>
          <label>
            Service Center ID
            <input
              value={serviceCenterId}
              onChange={(e) => setServiceCenterId(e.target.value)}
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
