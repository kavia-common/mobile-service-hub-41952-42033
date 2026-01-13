import React, { useState } from "react";
import { useAuth } from "../auth/AuthContext";
import { apiFetch } from "../lib/api";

type AuthResponse = {
  token: string;
  user: { id: string; name: string; email: string; role: string };
};

export function AuthPage() {
  const { setAuth } = useAuth();
  const [mode, setMode] = useState<"login" | "register">("login");
  const [name, setName] = useState("");
  const [role, setRole] = useState("Customer");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");

  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: React.FormEvent) {
    e.preventDefault();
    setError(null);
    setBusy(true);
    try {
      const body =
        mode === "login"
          ? { email, password }
          : { name, email, password, role };
      const res = await apiFetch<AuthResponse>(`/auth/${mode}`, {
        method: "POST",
        body: JSON.stringify(body)
      });
      setAuth(res.token, res.user);
    } catch (err: any) {
      setError(err?.message || "Failed");
    } finally {
      setBusy(false);
    }
  }

  return (
    <section className="card">
      <div className="row spaceBetween">
        <h1>{mode === "login" ? "Login" : "Register"}</h1>
        <button
          className="btn"
          type="button"
          onClick={() => setMode(mode === "login" ? "register" : "login")}
        >
          Switch to {mode === "login" ? "Register" : "Login"}
        </button>
      </div>

      <form onSubmit={submit} className="form">
        {mode === "register" && (
          <>
            <label>
              Name
              <input value={name} onChange={(e) => setName(e.target.value)} />
            </label>
            <label>
              Role
              <select value={role} onChange={(e) => setRole(e.target.value)}>
                <option>Customer</option>
                <option>Technician</option>
                <option>ServiceCenterAdmin</option>
                <option>SuperAdmin</option>
              </select>
            </label>
          </>
        )}

        <label>
          Email
          <input value={email} onChange={(e) => setEmail(e.target.value)} />
        </label>

        <label>
          Password
          <input
            type="password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
        </label>

        {error && <div className="error">{error}</div>}

        <button className="btn primary" disabled={busy}>
          {busy ? "Working..." : mode === "login" ? "Login" : "Create account"}
        </button>
      </form>
    </section>
  );
}
