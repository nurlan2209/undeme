const mongoose = require("mongoose");

const attemptSchema = new mongoose.Schema(
  {
    at: { type: Date, default: Date.now },
    channel: { type: String, required: true },
    success: { type: Boolean, required: true },
    error: { type: String, default: null },
  },
  { _id: false }
);

const sosEventSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    reason: { type: String, trim: true, maxlength: 500, default: "" },
    status: {
      type: String,
      enum: ["queued", "sent", "partially_sent", "failed"],
      default: "queued",
      index: true,
    },
    location: {
      latitude: { type: Number, required: true },
      longitude: { type: Number, required: true },
      accuracy: { type: Number, default: null },
      provider: { type: String, default: null },
      capturedAt: { type: Date, default: Date.now },
    },
    recipientsCount: { type: Number, default: 0 },
    attempts: { type: [attemptSchema], default: [] },
    dispatchedAt: { type: Date, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model("SosEvent", sosEventSchema);
