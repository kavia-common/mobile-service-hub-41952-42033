import mongoose from "mongoose";

const invoiceStatuses = ["Unpaid", "Paid", "Cancelled"];

const invoiceSchema = new mongoose.Schema(
  {
    service_request_id: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "ServiceRequest",
      required: true,
      unique: true
    },
    amount: { type: Number, required: true, min: 0 },
    status: { type: String, enum: invoiceStatuses, default: "Unpaid" },
    issued_at: { type: Date, default: () => new Date() }
  },
  { timestamps: { createdAt: "created_at", updatedAt: "updated_at" } }
);

invoiceSchema.index({ service_request_id: 1 }, { unique: true });

export const Invoice = mongoose.model("Invoice", invoiceSchema);
