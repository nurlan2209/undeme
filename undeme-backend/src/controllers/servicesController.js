const EMERGENCY_SERVICES = [
  {
    id: "ambulance",
    emoji: "🚑",
    number: "103",
    label: "Жедел жәрдем",
    description: "Шұғыл медициналық көмек",
    priority: 1,
  },
  {
    id: "police",
    emoji: "👮",
    number: "102",
    label: "Полиция",
    description: "Қауіпсіздік және құқықтық көмек",
    priority: 2,
  },
  {
    id: "fire",
    emoji: "🚒",
    number: "101",
    label: "Өрт сөндіру",
    description: "Өрт және құтқару қызметі",
    priority: 3,
  },
  {
    id: "single-number",
    emoji: "🆘",
    number: "112",
    label: "Бірыңғай нөмір",
    description: "Бірыңғай шұғыл қызмет",
    priority: 0,
  },
];

exports.getEmergencyServices = async (req, res, next) => {
  try {
    return res.json({
      items: EMERGENCY_SERVICES,
      note: "Тікелей қауіп болса, 112 нөміріне бірден хабарласыңыз",
      source: "backend",
    });
  } catch (error) {
    return next(error);
  }
};
