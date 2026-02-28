const validate = (schema, target = "body") => (req, res, next) => {
  const { value, error } = schema.validate(req[target], {
    abortEarly: false,
    stripUnknown: true,
  });

  if (error) {
    return res.status(400).json({
      message: "Валидация қатесі",
      details: error.details.map((item) => item.message),
    });
  }

  req[target] = value;
  return next();
};

module.exports = validate;
