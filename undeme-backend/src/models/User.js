const mongoose = require("mongoose");

const emergencyContactSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
      minlength: 2,
      maxlength: 80,
    },
    phone: {
      type: String,
      required: true,
      trim: true,
      maxlength: 32,
    },
    relation: {
      type: String,
      required: true,
      trim: true,
      maxlength: 50,
    },
  },
  { _id: true }
);

const userSchema = new mongoose.Schema(
  {
    fullName: {
      type: String,
      required: [true, "Толық аты-жөні міндетті"],
      trim: true,
      minlength: 2,
      maxlength: 120,
    },
    email: {
      type: String,
      required: [true, "Email міндетті"],
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    phone: {
      type: String,
      required: [true, "Телефон нөмірі міндетті"],
      trim: true,
      maxlength: 32,
    },
    password: {
      type: String,
      required: [true, "Құпия сөз міндетті"],
      minlength: 8,
      select: false,
    },
    emergencyContacts: {
      type: [emergencyContactSchema],
      default: [],
      validate: {
        validator: (value) => value.length <= 5,
        message: "Максимум 5 төтенше контакт рұқсат етіледі",
      },
    },
    settings: {
      sosVibration: { type: Boolean, default: true },
      autoLocation: { type: Boolean, default: true },
      emergencyNotif: { type: Boolean, default: true },
      soundAlerts: { type: Boolean, default: false },
    },
    isDeleted: {
      type: Boolean,
      default: false,
      index: true,
    },
    deletedAt: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model("User", userSchema);
