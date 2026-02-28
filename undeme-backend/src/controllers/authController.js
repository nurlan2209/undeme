const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const mongoose = require("mongoose");
const User = require("../models/User");
const env = require("../config/env");

const toPublicUser = (user) => ({
  id: user._id,
  fullName: user.fullName,
  email: user.email,
  phone: user.phone,
  emergencyContacts: user.emergencyContacts,
  settings: user.settings,
  createdAt: user.createdAt,
  updatedAt: user.updatedAt,
});

const signToken = (userId) =>
  jwt.sign({ userId: String(userId) }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn,
  });

exports.register = async (req, res, next) => {
  try {
    const { fullName, email, phone, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();

    const existingUser = await User.findOne({ email: normalizedEmail, isDeleted: false });
    if (existingUser) {
      return res.status(409).json({ message: "Бұл email тіркелген" });
    }

    const hashedPassword = await bcrypt.hash(password, 12);

    const user = new User({
      fullName,
      email: normalizedEmail,
      phone,
      password: hashedPassword,
    });

    await user.save();

    const token = signToken(user._id);

    return res.status(201).json({
      message: "Тіркелу сәтті өтті",
      token,
      user: toPublicUser(user),
    });
  } catch (error) {
    return next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const normalizedEmail = email.trim().toLowerCase();

    const user = await User.findOne({ email: normalizedEmail, isDeleted: false }).select("+password");
    if (!user) {
      return res.status(401).json({ message: "Email немесе құпия сөз қате" });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Email немесе құпия сөз қате" });
    }

    const token = signToken(user._id);

    return res.json({
      message: "Кіру сәтті өтті",
      token,
      user: toPublicUser(user),
    });
  } catch (error) {
    return next(error);
  }
};

exports.getProfile = async (req, res, next) => {
  try {
    const user = await User.findOne({ _id: req.userId, isDeleted: false });

    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    return res.json({ user: toPublicUser(user) });
  } catch (error) {
    return next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const { fullName, phone, settings } = req.body;

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    if (fullName) user.fullName = fullName;
    if (phone) user.phone = phone;
    if (settings) user.settings = { ...user.settings, ...settings };

    await user.save();

    return res.json({
      message: "Профиль жаңартылды",
      user: toPublicUser(user),
    });
  } catch (error) {
    return next(error);
  }
};

exports.addEmergencyContact = async (req, res, next) => {
  try {
    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    if (user.emergencyContacts.length >= 5) {
      return res.status(400).json({ message: "Максимум 5 контакт рұқсат етіледі" });
    }

    user.emergencyContacts.push(req.body);
    await user.save();

    const contact = user.emergencyContacts[user.emergencyContacts.length - 1];
    return res.status(201).json({
      message: "Контакт қосылды",
      contact,
      contacts: user.emergencyContacts,
    });
  } catch (error) {
    return next(error);
  }
};

exports.updateEmergencyContact = async (req, res, next) => {
  try {
    const { contactId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(contactId)) {
      return res.status(400).json({ message: "Жарамсыз contactId" });
    }

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    const contact = user.emergencyContacts.id(contactId);
    if (!contact) {
      return res.status(404).json({ message: "Контакт табылмады" });
    }

    if (req.body.name) contact.name = req.body.name;
    if (req.body.phone) contact.phone = req.body.phone;
    if (req.body.relation) contact.relation = req.body.relation;

    await user.save();

    return res.json({
      message: "Контакт жаңартылды",
      contact,
      contacts: user.emergencyContacts,
    });
  } catch (error) {
    return next(error);
  }
};

exports.deleteEmergencyContact = async (req, res, next) => {
  try {
    const { contactId } = req.params;

    if (!mongoose.Types.ObjectId.isValid(contactId)) {
      return res.status(400).json({ message: "Жарамсыз contactId" });
    }

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    const contact = user.emergencyContacts.id(contactId);
    if (!contact) {
      return res.status(404).json({ message: "Контакт табылмады" });
    }

    contact.deleteOne();
    await user.save();

    return res.json({
      message: "Контакт жойылды",
      contacts: user.emergencyContacts,
    });
  } catch (error) {
    return next(error);
  }
};

exports.deleteAccount = async (req, res, next) => {
  try {
    const { password } = req.body;

    const user = await User.findOne({ _id: req.userId, isDeleted: false }).select("+password");
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);
    if (!isPasswordValid) {
      return res.status(401).json({ message: "Құпия сөз қате" });
    }

    user.isDeleted = true;
    user.deletedAt = new Date();
    user.email = `deleted_${Date.now()}_${user.email}`;
    user.phone = `deleted_${Date.now()}`;
    user.emergencyContacts = [];
    await user.save();

    return res.json({ message: "Аккаунт сәтті жойылды" });
  } catch (error) {
    return next(error);
  }
};
