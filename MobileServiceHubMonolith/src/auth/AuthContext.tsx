import React, { createContext, useContext, useMemo, useState } from "react";

type User = { id: string; email: string; name: string; role: string } | null;

type AuthContextValue = {
  token: string | null;
  user: User;
  setAuth: (token: string, user: NonNullable<User>) => void;
  logout: () => void;
};

const AuthContext = createContext<AuthContextValue | null>(null);

function getStoredToken() {
  try {
    return localStorage.getItem("msh_token");
  } catch {
    return null;
  }
}

function getStoredUser(): User {
  try {
    const raw = localStorage.getItem("msh_user");
    return raw ? JSON.parse(raw) : null;
  } catch {
    return null;
  }
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [token, setToken] = useState<string | null>(getStoredToken());
  const [user, setUser] = useState<User>(getStoredUser());

  const value = useMemo<AuthContextValue>(
    () => ({
      token,
      user,
      setAuth: (t, u) => {
        setToken(t);
        setUser(u);
        localStorage.setItem("msh_token", t);
        localStorage.setItem("msh_user", JSON.stringify(u));
      },
      logout: () => {
        setToken(null);
        setUser(null);
        localStorage.removeItem("msh_token");
        localStorage.removeItem("msh_user");
      }
    }),
    [token, user]
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
}

// PUBLIC_INTERFACE
/**
 * Hook to access authentication state.
 */
export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
}
