import mongoose from "mongoose";

const technicianSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    skills: { type: [String], default: [] },
    availability: { type: String, default: "Available" },
    service_center_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceCenter",
      required: true
    },
    is_active: { type: Boolean, default: true }
  },
  { timestamps: { createdAt: "created_at", updatedAt: "updated_at" } }
);

technicianSchema.index({ service_center_id: 1 });

export const Technician = mongoose.model("Technician", technicianSchema);
