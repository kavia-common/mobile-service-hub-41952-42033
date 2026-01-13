import { Router } from "express";
import { ServiceRequest } from "../models/ServiceRequest.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

export const serviceRequestsRouter = Router();

// PUBLIC_INTERFACE
/**
 * GET /api/service-requests
 * - SuperAdmin/ServiceCenterAdmin: list all
 * - Customer: list own
 */
serviceRequestsRouter.get("/", requireAuth, async (req, res, next) => {
  try {
    const role = req.user.role;
    const query =
      role === "Customer" ? { customer_id: req.user.id } : {};

    const items = await ServiceRequest.find(query).sort({ created_at: -1 });
    res.json(items);
  } catch (err) {
    next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * POST /api/service-requests
 * - Customer creates for themselves
 * Body: { description, service_center_id?, technician_id? }
 */
serviceRequestsRouter.post("/", requireAuth, requireRole(["Customer", "SuperAdmin"]), async (req, res, next) => {
  try {
    const { description, service_center_id, technician_id } = req.body || {};
    const created = await ServiceRequest.create({
      customer_id: req.user.role === "Customer" ? req.user.id : req.body.customer_id,
      description: description || "",
      service_center_id: service_center_id || undefined,
      technician_id: technician_id || undefined,
      status: "Pending"
    });
    res.status(201).json(created);
  } catch (err) {
    next(err);
  }
});

// PUBLIC_INTERFACE
/**
 * PATCH /api/service-requests/:id (ServiceCenterAdmin/SuperAdmin)
 * Body may include: { status, technician_id, service_center_id, description }
 */
serviceRequestsRouter.patch(
  "/:id",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const allowed = ["status", "technician_id", "service_center_id", "description"];
      const patch = {};
      for (const k of allowed) {
        if (k in (req.body || {})) patch[k] = req.body[k];
      }

      const updated = await ServiceRequest.findByIdAndUpdate(req.params.id, patch, {
        new: true
      });
      if (!updated) return res.status(404).json({ error: { message: "Not found" } });
      res.json(updated);
    } catch (err) {
      next(err);
    }
  }
);
