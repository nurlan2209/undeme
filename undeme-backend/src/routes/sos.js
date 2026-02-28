const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const validate = require("../middleware/validate");
const { sosLimiter } = require("../middleware/rateLimits");
const sosController = require("../controllers/sosController");
const { triggerSosSchema, retrySosSchema } = require("../validators/sosSchemas");

router.post("/trigger", auth, sosLimiter, validate(triggerSosSchema), sosController.triggerSos);
router.post("/retry", auth, sosLimiter, validate(retrySosSchema), sosController.retrySos);
router.get("/history", auth, sosController.getSosHistory);

module.exports = router;
