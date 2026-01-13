import React, { useEffect, useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { apiFetch } from "../lib/api";

type Invoice = {
  _id: string;
  service_request_id: string;
  amount: number;
  status: string;
  issued_at: string;
};

export function InvoicesPage() {
  const { token } = useAuth();
  const [items, setItems] = useState<Invoice[]>([]);
  const [serviceRequestId, setServiceRequestId] = useState("");
  const [amount, setAmount] = useState("0");
  const [status, setStatus] = useState("Unpaid");
  const [error, setError] = useState<string | null>(null);

  async function load() {
    if (!token) return;
    setError(null);
    try {
      const res = await apiFetch<Invoice[]>("/invoices", { token });
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
      await apiFetch<Invoice>("/invoices", {
        method: "POST",
        token,
        body: JSON.stringify({
          service_request_id: serviceRequestId,
          amount: Number(amount),
          status
        })
      });
      setServiceRequestId("");
      setAmount("0");
      setStatus("Unpaid");
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  }

  return (
    <section className="grid">
      <div className="card">
        <h1>Invoices</h1>
        {!token && <div className="hint">Login to view/create records.</div>}
        {error && <div className="error">{error}</div>}
        <table className="table">
          <thead>
            <tr>
              <th>Service Request ID</th>
              <th>Amount</th>
              <th>Status</th>
              <th>Issued At</th>
            </tr>
          </thead>
          <tbody>
            {items.map((inv) => (
              <tr key={inv._id}>
                <td className="mono">{inv.service_request_id}</td>
                <td>{inv.amount}</td>
                <td>{inv.status}</td>
                <td>{new Date(inv.issued_at).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      <div className="card">
        <h2>Create Invoice</h2>
        <p className="muted">Requires ServiceCenterAdmin or SuperAdmin.</p>
        <form className="form" onSubmit={create}>
          <label>
            Service Request ID
            <input
              value={serviceRequestId}
              onChange={(e) => setServiceRequestId(e.target.value)}
            />
          </label>
          <label>
            Amount
            <input value={amount} onChange={(e) => setAmount(e.target.value)} />
          </label>
          <label>
            Status
            <select value={status} onChange={(e) => setStatus(e.target.value)}>
              <option>Unpaid</option>
              <option>Paid</option>
              <option>Cancelled</option>
            </select>
          </label>
          <button className="btn primary" disabled={!token}>
            Create
          </button>
        </form>
      </div>
    </section>
  );
}
