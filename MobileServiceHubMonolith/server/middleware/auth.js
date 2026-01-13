import jwt from "jsonwebtoken";

/**
 * NOTE: This is auth scaffolding (sufficient for dev/demo).
 * Env vars (set by orchestrator):
 * - JWT_SECRET
 */
const JWT_SECRET = process.env.JWT_SECRET || "dev-insecure-secret-change-me";

// PUBLIC_INTERFACE
/**
 * Requires a valid Bearer token; attaches req.user = { id, role, email }.
 */
export function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization || "";
  const [scheme, token] = authHeader.split(" ");

  if (scheme !== "Bearer" || !token) {
    return res.status(401).json({ error: { message: "Missing Bearer token" } });
  }

  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.user = payload;
    return next();
  } catch {
    return res.status(401).json({ error: { message: "Invalid token" } });
  }
}

// PUBLIC_INTERFACE
/**
 * Requires the authenticated user to have one of the specified roles.
 * @param {string[]} roles
 */
export function requireRole(roles) {
  return (req, res, next) => {
    const role = req.user?.role;
    if (!role || !roles.includes(role)) {
      return res.status(403).json({ error: { message: "Forbidden" } });
    }
    return next();
  };
}

// PUBLIC_INTERFACE
/**
 * Signs a JWT for the given user.
 */
export function signToken(user) {
  return jwt.sign(
    { id: user._id.toString(), role: user.role, email: user.email },
    JWT_SECRET,
    { expiresIn: "7d" }
  );
}
