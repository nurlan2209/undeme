const express = require("express");
const router = express.Router();
const servicesController = require("../controllers/servicesController");

router.get("/emergency", servicesController.getEmergencyServices);

module.exports = router;
