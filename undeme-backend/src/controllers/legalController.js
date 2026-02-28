const LEGAL_TOPICS = [
  {
    id: "constitutional-rights-emergency",
    category: "Конституциялық құқықтар",
    title: "Төтенше жағдайларда азаматтардың құқықтары",
    description: "ҚР Конституциясы 15-бап",
  },
  {
    id: "medical-emergency-help",
    category: "Медициналық",
    title: "Төтенше медициналық көмек",
    description: "Денсаулық сақтау туралы заң 88-бап",
  },
  {
    id: "state-protection-danger",
    category: "Жеке қауіпсіздік",
    title: "Қауіпті жағдайларда мемлекеттік қорғау",
    description: "ҚР Азаматтық кодексі 9-тарау",
  },
  {
    id: "mandatory-reporting",
    category: "Жеке қауіпсіздік",
    title: "Төтенше қызметтерге хабарлау міндеті",
    description: "ҚР ӘҚК 339-бап",
  },
  {
    id: "location-privacy",
    category: "Конституциялық құқықтар",
    title: "Жеке деректерді қорғау және орын ақпараты",
    description: "Жеке деректер туралы заң 6-бап",
  },
  {
    id: "domestic-violence-protection",
    category: "Жеке қауіпсіздік",
    title: "Отбасылық зорлық-зомбылықтан қорғау",
    description: "Отбасылық зорлық-зомбылық туралы заң",
  },
  {
    id: "police-interaction",
    category: "Полиция",
    title: "Полициямен өзара іс-қимыл",
    description: "Полиция қызметі туралы заң 5-бап",
  },
  {
    id: "medical-confidentiality",
    category: "Медициналық",
    title: "Медициналық құпияны сақтау",
    description: "Денсаулық сақтау туралы заң 91-бап",
  },
  {
    id: "civil-procedure-rights",
    category: "Конституциялық құқықтар",
    title: "Азаматтық сот ісін жүргізу құқықтары",
    description: "ҚР Конституциясы 13-бап",
  },
  {
    id: "natural-disaster-actions",
    category: "Жеке қауіпсіздік",
    title: "Табиғи апаттар кезіндегі іс-қимылдар",
    description: "Төтенше жағдайлар туралы заң",
  },
];

const filterTopics = ({ category, query }) => {
  let topics = [...LEGAL_TOPICS];

  if (category && category !== "Барлығы") {
    topics = topics.filter((topic) => topic.category === category);
  }

  if (query) {
    const normalized = query.toLowerCase();
    topics = topics.filter(
      (topic) =>
        topic.title.toLowerCase().includes(normalized) ||
        topic.description.toLowerCase().includes(normalized) ||
        topic.category.toLowerCase().includes(normalized)
    );
  }

  return topics;
};

exports.getLegalTopics = async (req, res, next) => {
  try {
    const category = req.query.category ? String(req.query.category) : "Барлығы";
    const query = req.query.query ? String(req.query.query).trim() : "";

    const topics = filterTopics({ category, query });
    const categories = ["Барлығы", ...new Set(LEGAL_TOPICS.map((topic) => topic.category))];

    return res.json({
      categories,
      total: topics.length,
      items: topics,
      source: "backend",
    });
  } catch (error) {
    return next(error);
  }
};
