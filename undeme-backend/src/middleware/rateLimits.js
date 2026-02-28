const rateLimit = require("express-rate-limit");

const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 500,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Сұраулар тым көп, кейінірек қайталап көріңіз" },
});

const authLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "Кіру әрекеттері тым көп, 15 минуттан кейін көріңіз" },
});

const sosLimiter = rateLimit({
  windowMs: 5 * 60 * 1000,
  max: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: { message: "SOS сұраулары тым жиі жіберілді" },
});

module.exports = {
  globalLimiter,
  authLimiter,
  sosLimiter,
};
