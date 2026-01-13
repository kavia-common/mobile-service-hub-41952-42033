import { Router } from "express";
import { Invoice } from "../models/Invoice.js";
import { requireAuth, requireRole } from "../middleware/auth.js";

export const invoicesRouter = Router();

// PUBLIC_INTERFACE
/**
 * GET /api/invoices (SuperAdmin, ServiceCenterAdmin)
 */
invoicesRouter.get(
  "/",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const items = await Invoice.find().sort({ issued_at: -1 });
      res.json(items);
    } catch (err) {
      next(err);
    }
  }
);

// PUBLIC_INTERFACE
/**
 * POST /api/invoices (SuperAdmin, ServiceCenterAdmin)
 * Body: { service_request_id, amount, status? }
 */
invoicesRouter.post(
  "/",
  requireAuth,
  requireRole(["SuperAdmin", "ServiceCenterAdmin"]),
  async (req, res, next) => {
    try {
      const { service_request_id, amount, status } = req.body || {};
      if (!service_request_id || amount === undefined) {
        return res.status(400).json({ error: { message: "Missing fields" } });
      }
      const created = await Invoice.create({
        service_request_id,
        amount: Number(amount),
        status: status || "Unpaid",
        issued_at: new Date()
      });
      res.status(201).json(created);
    } catch (err) {
      next(err);
    }
  }
);
