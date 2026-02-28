const express = require("express");
const router = express.Router();
const auth = require("../middleware/auth");
const validate = require("../middleware/validate");
const aiController = require("../controllers/aiController");
const { chatSchema } = require("../validators/aiSchemas");

router.post("/chat", auth, validate(chatSchema), aiController.chat);
router.get("/history", auth, aiController.history);

module.exports = router;
