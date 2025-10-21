const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, "Толық аты-жөні міндетті"],
      trim: true,
    },
    email: {
      type: String,
      required: [true, "Email міндетті"],
      unique: true,
      lowercase: true,
      trim: true,
    },
    phone: {
      type: String,
      required: [true, "Телефон нөмірі міндетті"],
      trim: true,
    },
    password: {
      type: String,
      required: [true, "Құпия сөз міндетті"],
      minlength: 6,
    },
    emergencyContacts: [
      {
        name: String,
        phone: String,
        relation: String,
      },
    ],
    settings: {
      sosVibration: { type: Boolean, default: true },
      autoLocation: { type: Boolean, default: true },
      emergencyNotif: { type: Boolean, default: true },
      soundAlerts: { type: Boolean, default: false },
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);
