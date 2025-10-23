const express = require("express");
const dotenv = require("dotenv");
const cors = require("cors");
const connectDB = require("./config/db");
const authRoutes = require("./routes/auth");

// Загрузка переменных окружения
dotenv.config();

const app = express();

// Подключение к MongoDB
connectDB();

// КРИТИЧЕСКИ ВАЖНО: CORS должен быть ПЕРВЫМ middleware
// Настройка CORS для разрешения запросов от Flutter Web
const corsOptions = {
  origin: function (origin, callback) {
    // Разрешить запросы без origin (например, мобильные приложения)
    // или с любым origin в режиме разработки
    callback(null, true);
  },
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
  allowedHeaders: [
    "Content-Type",
    "Authorization",
    "X-Requested-With",
    "Accept",
  ],
  exposedHeaders: ["Content-Length", "X-JSON"],
  maxAge: 86400, // 24 часа
};

app.use(cors(corsOptions));

// Парсинг JSON
app.use(express.json());

// Логирование запросов (для отладки)
app.use((req, res, next) => {
  console.log(`${req.method} ${req.path}`);
  next();
});

// Маршруты
app.use("/api/auth", authRoutes);

// Базовый маршрут
app.get("/", (req, res) => {
  res.json({
    message: "Undeme API работает",
    cors: "enabled",
    port: process.env.PORT || 5002,
  });
});

// Обработка ошибок
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ message: "Сервер қатесі", error: err.message });
});

const PORT = process.env.PORT || 5002;

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
  console.log(`CORS enabled for all origins`);
});
