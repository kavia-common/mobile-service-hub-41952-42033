import mongoose from "mongoose";

const serviceCenterSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    address: { type: String, default: "" },
    admin_id: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true }
  },
  { timestamps: { createdAt: "created_at", updatedAt: "updated_at" } }
);

serviceCenterSchema.index({ admin_id: 1 });

export const ServiceCenter = mongoose.model("ServiceCenter", serviceCenterSchema);
