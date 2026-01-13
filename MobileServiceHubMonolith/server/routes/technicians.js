import { Router } from "express";
import { Technician } from "../models/Technician.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

export const techniciansRouter = Router();

// PUBLIC_INTERFACE
/**
 * GET /api/technicians (SuperAdmin, ServiceCenterAdmin)
 */
techniciansRouter.get(
  "/",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const items = await Technician.find().sort({ created_at: -1 });
      res.json(items);
    } catch (err) {
      next(err);
    }
  }
);

// PUBLIC_INTERFACE
/**
 * POST /api/technicians (ServiceCenterAdmin or SuperAdmin)
 * Body: { name, skills?, availability?, service_center_id, is_active? }
 */
techniciansRouter.post(
  "/",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const { name, skills, availability, service_center_id, is_active } = req.body || {};
      if (!name || !service_center_id) {
        return res.status(400).json({ error: { message: "Missing fields" } });
      }
      const created = await Technician.create({
        name,
        skills: Array.isArray(skills) ? skills : [],
        availability: availability || "Available",
        service_center_id,
        is_active: is_active ?? true
      });
      res.status(201).json(created);
    } catch (err) {
      next(err);
    }
  }
);
