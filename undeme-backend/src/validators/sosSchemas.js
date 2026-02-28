const Joi = require("joi");

const triggerSosSchema = Joi.object({
  reason: Joi.string().trim().allow("").max(500),
  location: Joi.object({
    latitude: Joi.number().min(-90).max(90).required(),
    longitude: Joi.number().min(-180).max(180).required(),
    accuracy: Joi.number().min(0).max(5000),
    provider: Joi.string().trim().max(50),
    capturedAt: Joi.date().iso(),
  }).required(),
  force: Joi.boolean().default(false),
});

const retrySosSchema = Joi.object({
  eventId: Joi.string().hex().length(24).required(),
});

module.exports = {
  triggerSosSchema,
  retrySosSchema,
};
