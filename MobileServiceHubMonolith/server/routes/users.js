import { Router } from "express";
import bcrypt from "bcryptjs";
import { User } from "../models/User.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

export const usersRouter = Router();

// PUBLIC_INTERFACE
/**
 * GET /api/users (SuperAdmin only)
 */
usersRouter.get("/", requireAuth, requireRole(["SuperAdmin"]), async (req, res, next) => {
  try {
    const users = await User.find().select("-password_hash").sort({ created_at: -1 });
    res.json(users);
  } catch (err) {
    next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * GET /api/users/me (any authenticated)
 */
usersRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const user = await User.findById(req.user.id).select("-password_hash");
    if (!user) return res.status(404).json({ error: { message: "Not found" } });
    res.json(user);
  } catch (err) {
    next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * POST /api/users (SuperAdmin only) - create user (admin action)
 */
usersRouter.post("/", requireAuth, requireRole(["SuperAdmin"]), async (req, res, next) => {
  try {
    const { name, email, role, password, is_active } = req.body || {};
    if (!name || !email || !role || !password) {
      return res.status(400).json({ error: { message: "Missing fields" } });
    }

    const password_hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      name,
      email,
      role,
      password_hash,
      is_active: is_active ?? true
    });

    res.status(201).json({ id: user._id });
  } catch (err) {
    next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * DELETE /api/users/:id (SuperAdmin only)
 */
usersRouter.delete("/:id", requireAuth, requireRole(["SuperAdmin"]), async (req, res, next) => {
  try {
    await User.findByIdAndDelete(req.params.id);
    res.json({ ok: true });
  } catch (err) {
    next(err);
  }
});
