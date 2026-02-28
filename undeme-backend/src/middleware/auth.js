const jwt = require("jsonwebtoken");
const env = require("../config/env");

const auth = (req, res, next) => {
  try {
    const authHeader = req.header("Authorization");

    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res.status(401).json({ message: "Аутентификация қажет" });
    }

    const token = authHeader.slice(7).trim();
    const decoded = jwt.verify(token, env.jwtSecret);

    req.userId = decoded.userId;
    next();
  } catch (error) {
    return res.status(401).json({ message: "Жарамсыз токен" });
  }
};

module.exports = auth;
