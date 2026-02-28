const express = require("express");
const router = express.Router();
const authController = require("../controllers/authController");
const auth = require("../middleware/auth");
const validate = require("../middleware/validate");
const { authLimiter } = require("../middleware/rateLimits");
const {
  registerSchema,
  loginSchema,
  updateProfileSchema,
  createContactSchema,
  updateContactSchema,
  deleteAccountSchema,
} = require("../validators/authSchemas");

router.post("/register", authLimiter, validate(registerSchema), authController.register);
router.post("/login", authLimiter, validate(loginSchema), authController.login);
router.get("/profile", auth, authController.getProfile);
router.put("/profile", auth, validate(updateProfileSchema), authController.updateProfile);

router.post(
  "/profile/contacts",
  auth,
  validate(createContactSchema),
  authController.addEmergencyContact
);
router.put(
  "/profile/contacts/:contactId",
  auth,
  validate(updateContactSchema),
  authController.updateEmergencyContact
);
router.delete("/profile/contacts/:contactId", auth, authController.deleteEmergencyContact);
router.delete("/profile/account", auth, validate(deleteAccountSchema), authController.deleteAccount);

module.exports = router;
