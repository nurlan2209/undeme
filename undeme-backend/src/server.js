const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const connectDB = require("./config/db");
const env = require("./config/env");
const authRoutes = require("./routes/auth");
const sosRoutes = require("./routes/sos");
const aiRoutes = require("./routes/ai");
const legalRoutes = require("./routes/legal");
const servicesRoutes = require("./routes/services");
const { globalLimiter } = require("./middleware/rateLimits");
const errorHandler = require("./middleware/errorHandler");

const app = express();

connectDB();

// Trust first reverse proxy (nginx) so rate limiting uses real client IP.
app.set("trust proxy", 1);

const corsOptions = {
  origin(origin, callback) {
    if (!origin) {
      return callback(null, true);
    }

    if (env.nodeEnv !== "production") {
      return callback(null, true);
    }

    if (env.corsOrigins.includes(origin)) {
      return callback(null, true);
    }

    return callback(new Error("Not allowed by CORS"));
  },
  credentials: false,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: ["Content-Type", "Authorization"],
  maxAge: 86400,
};

app.use(helmet());
app.use(cors(corsOptions));
app.use(globalLimiter);
app.use(express.json({ limit: "1mb" }));

app.use((req, res, next) => {
  console.log(`${new Date().toISOString()} ${req.method} ${req.path}`);
  next();
});

app.get("/", (req, res) => {
  res.json({
    service: "Undeme API",
    status: "ok",
    env: env.nodeEnv,
  });
});

app.use("/api/auth", authRoutes);
app.use("/api/sos", sosRoutes);
app.use("/api/ai", aiRoutes);
app.use("/api/legal", legalRoutes);
app.use("/api/services", servicesRoutes);

app.use(errorHandler);

app.listen(env.port, () => {
  console.log(`Server running on port ${env.port}`);
});
