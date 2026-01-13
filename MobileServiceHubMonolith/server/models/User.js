import mongoose from "mongoose";

const roles = ["SuperAdmin", "ServiceCenterAdmin", "Technician", "Customer"];

const userSchema = new mongoose.Schema(
  {
    name: { type: String, required: true, trim: true },
    email: { type: String, required: true, unique: true, lowercase: true },
    role: { type: String, enum: roles, default: "Customer", required: true },
    password_hash: { type: String, required: true },
    is_active: { type: Boolean, default: true }
  },
  { timestamps: { createdAt: "created_at", updatedAt: "updated_at" } }
);

userSchema.index({ email: 1 }, { unique: true });

export const User = mongoose.model("User", userSchema);
