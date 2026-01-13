import mongoose from "mongoose";

const statuses = ["Pending", "Assigned", "InProgress", "Completed", "Cancelled"];

const serviceRequestSchema = new mongoose.Schema(
  {
    customer_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true
    },
    technician_id: { type: mongoose.Schema.Types.ObjectId, ref: "Technician" },
    service_center_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceCenter"
    },
    status: { type: String, enum: statuses, default: "Pending" },
    description: { type: String, default: "" }
  },
  { timestamps: { createdAt: "created_at", updatedAt: "updated_at" } }
);

serviceRequestSchema.index({ status: 1 });
serviceRequestSchema.index({ customer_id: 1 });

export const ServiceRequest = mongoose.model("ServiceRequest", serviceRequestSchema);
