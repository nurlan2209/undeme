const dotenv = require("dotenv");
const Joi = require("joi");

dotenv.config();

const schema = Joi.object({
  NODE_ENV: Joi.string().valid("development", "test", "production").default("development"),
  PORT: Joi.number().port().default(5002),
  MONGODB_URI: Joi.string().uri().required(),
  JWT_SECRET: Joi.string().min(32).required(),
  JWT_EXPIRES_IN: Joi.string().default("7d"),
  CORS_ORIGINS: Joi.string().allow(""),
  SOS_WEBHOOK_URL: Joi.string().uri().allow(""),
  SOS_COOLDOWN_SECONDS: Joi.number().integer().min(5).default(30),
  GEMINI_API_KEY: Joi.string().allow(""),
  GEMINI_MODEL: Joi.string().trim().default("gemini-3.5-flash-preview"),
  WHATSAPP_BUSINESS_TOKEN: Joi.string().allow(""),
  WHATSAPP_PHONE_NUMBER_ID: Joi.string().allow(""),
  WHATSAPP_API_VERSION: Joi.string().trim().default("v22.0"),
  WHATSAPP_TEMPLATE_NAME: Joi.string().trim().allow(""),
  WHATSAPP_TEMPLATE_LANGUAGE: Joi.string().trim().default("en_US"),
});

const { value, error } = schema.validate(process.env, {
  allowUnknown: true,
  abortEarly: false,
  stripUnknown: false,
});

if (error) {
  const details = error.details.map((item) => item.message).join("; ");
  throw new Error(`Environment validation failed: ${details}`);
}

const env = {
  nodeEnv: value.NODE_ENV,
  port: value.PORT,
  mongoUri: value.MONGODB_URI,
  jwtSecret: value.JWT_SECRET,
  jwtExpiresIn: value.JWT_EXPIRES_IN,
  corsOrigins: (value.CORS_ORIGINS || "")
    .split(",")
    .map((origin) => origin.trim())
    .filter(Boolean),
  sosWebhookUrl: value.SOS_WEBHOOK_URL || null,
  sosCooldownSeconds: value.SOS_COOLDOWN_SECONDS,
  geminiApiKey: value.GEMINI_API_KEY || "",
  geminiModel: value.GEMINI_MODEL,
  whatsappBusinessToken: value.WHATSAPP_BUSINESS_TOKEN || "",
  whatsappPhoneNumberId: value.WHATSAPP_PHONE_NUMBER_ID || "",
  whatsappApiVersion: value.WHATSAPP_API_VERSION,
  whatsappTemplateName: value.WHATSAPP_TEMPLATE_NAME || "",
  whatsappTemplateLanguage: value.WHATSAPP_TEMPLATE_LANGUAGE,
};

module.exports = env;
