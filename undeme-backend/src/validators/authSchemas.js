const Joi = require("joi");

const email = Joi.string().trim().email().max(160);
const phone = Joi.string().trim().min(7).max(32);
const password = Joi.string().min(8).max(128);

const contactSchema = Joi.object({
  name: Joi.string().trim().min(2).max(80).required(),
  phone: phone.required(),
  relation: Joi.string().trim().min(2).max(50).required(),
});

const registerSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(120).required(),
  email: email.required(),
  phone: phone.required(),
  password: password.required(),
});

const loginSchema = Joi.object({
  email: email.required(),
  password: Joi.string().required(),
});

const updateProfileSchema = Joi.object({
  fullName: Joi.string().trim().min(2).max(120),
  phone,
  settings: Joi.object({
    sosVibration: Joi.boolean(),
    autoLocation: Joi.boolean(),
    emergencyNotif: Joi.boolean(),
    soundAlerts: Joi.boolean(),
  }).min(1),
}).min(1);

const createContactSchema = contactSchema;

const updateContactSchema = Joi.object({
  name: Joi.string().trim().min(2).max(80),
  phone,
  relation: Joi.string().trim().min(2).max(50),
}).min(1);

const deleteAccountSchema = Joi.object({
  password: Joi.string().required(),
});

module.exports = {
  registerSchema,
  loginSchema,
  updateProfileSchema,
  createContactSchema,
  updateContactSchema,
  deleteAccountSchema,
};
