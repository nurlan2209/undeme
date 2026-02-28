const Joi = require("joi");

const chatSchema = Joi.object({
  message: Joi.string().trim().min(3).max(1200).required(),
  context: Joi.string()
    .trim()
    .valid("general", "detention", "medical", "domestic_violence", "legal")
    .default("general"),
});

module.exports = {
  chatSchema,
};
