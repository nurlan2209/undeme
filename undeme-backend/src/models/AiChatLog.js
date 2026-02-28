const mongoose = require("mongoose");

const aiChatLogSchema = new mongoose.Schema(
  {
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      index: true,
    },
    message: { type: String, required: true, maxlength: 1200 },
    context: {
      type: String,
      enum: ["general", "detention", "medical", "domestic_violence", "legal"],
      required: true,
      default: "general",
    },
    response: { type: String, required: true },
    disclaimerShown: { type: Boolean, default: true },
    safetyFlags: { type: [String], default: [] },
    provider: { type: String, default: "local_safe_fallback" },
    model: { type: String, default: null },
    usedFallback: { type: Boolean, default: false },
  },
  { timestamps: true }
);

module.exports = mongoose.model("AiChatLog", aiChatLogSchema);
