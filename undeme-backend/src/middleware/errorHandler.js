const errorHandler = (err, req, res, next) => {
  console.error(err);

  if (err.name === "ValidationError") {
    return res.status(400).json({ message: "Валидация қатесі" });
  }

  return res.status(500).json({ message: "Ішкі сервер қатесі" });
};

module.exports = errorHandler;
