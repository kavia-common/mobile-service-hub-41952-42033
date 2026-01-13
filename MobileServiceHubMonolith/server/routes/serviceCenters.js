import { Router } from "express";
import { ServiceCenter } from "../models/ServiceCenter.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

export const serviceCentersRouter = Router();

// PUBLIC_INTERFACE
/**
 * GET /api/service-centers (SuperAdmin, ServiceCenterAdmin)
 */
serviceCentersRouter.get(
  "/",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const items = await ServiceCenter.find().sort({ created_at: -1 });
      res.json(items);
    } catch (err) {
      next(err);
    }
  }
);

// PUBLIC_INTERFACE
/**
 * POST /api/service-centers (SuperAdmin only for now)
 * Body: { name, address?, admin_id }
 */
serviceCentersRouter.post("/", requireAuth, requireRole(["SuperAdmin"]), async (req, res, next) => {
  try {
    const { name, address, admin_id } = req.body || {};
    if (!name || !admin_id) {
      return res.status(400).json({ error: { message: "Missing fields" } });
    }
    const created = await ServiceCenter.create({ name, address: address || "", admin_id });
    res.status(201).json(created);
  } catch (err) {
    next(err);
  }
});
