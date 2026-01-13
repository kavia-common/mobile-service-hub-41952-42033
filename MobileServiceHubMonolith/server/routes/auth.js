import { Router } from "express";
import bcrypt from "bcryptjs";
import { User } from "../models/User.js";
import { signToken } from "../middleware/auth.js";

export const authRouter = Router();

// PUBLIC_INTERFACE
/**
 * POST /api/auth/register
 * Body: { name, email, password, role? }
 */
authRouter.post("/register", async (req, res, next) => {
  try {
    const { name, email, password, role } = req.body || {};
    if (!name || !email || !password) {
      return res.status(400).json({ error: { message: "Missing fields" } });
    }

    const existing = await User.findOne({ email });
    if (existing) {
      return res.status(409).json({ error: { message: "Email already in use" } });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email,
      role: role || "Customer",
      password_hash,
      is_active: true
    });

    const token = signToken(user);
    return res.status(201).json({
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role }
    });
  } catch (err) {
    return next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * POST /api/auth/login
 * Body: { email, password }
 */
authRouter.post("/login", async (req, res, next) => {
  try {
    const { email, password } = req.body || {};
    if (!email || !password) {
      return res.status(400).json({ error: { message: "Missing fields" } });
    }

    const user = await User.findOne({ email });
    if (!user || !user.is_active) {
      return res.status(401).json({ error: { message: "Invalid credentials" } });
    }

    const ok = await bcrypt.compare(password, user.password_hash);
    if (!ok) {
      return res.status(401).json({ error: { message: "Invalid credentials" } });
    }

    const token = signToken(user);
    return res.json({
      token,
      user: { id: user._id, name: user.name, email: user.email, role: user.role }
    });
  } catch (err) {
    return next(err);
  }
});
