const express = require("express");
const router = express.Router();
const legalController = require("../controllers/legalController");

router.get("/topics", legalController.getLegalTopics);

module.exports = router;
