const DISCLAIMER =
  "Маңызды: бұл ақпарат жалпы сипатта, заңгерлік/медициналық кәсіби кеңесті алмастырмайды. Қауіп төнсе, 112 нөміріне дереу хабарласыңыз.";

const SAFETY_TRIGGERS = [
  { key: "self_harm", regex: /(өзіме\s*қол|suicide|kill myself|өз-өзіне)/i },
  { key: "violence", regex: /(пышақ|қару|kill|өлтіремін|шабуыл)/i },
  { key: "detention", regex: /(ұстады|задержание|detain|полиция)/i },
];

const TEMPLATES = {
  detention: [
    "1) Сабыр сақтаңыз, қарсылық көрсетпеңіз.",
    "2) Қызметкердің аты-жөні мен бөлімшесін нақтылаңыз.",
    "3) Ұстау себебін және құқықтарыңызды түсіндіруді талап етіңіз.",
    "4) Туысыңызға және адвокатқа хабарласу құқығын қолданыңыз.",
    "5) Құжаттарға оқымай қол қоймаңыз.",
  ],
  medical: [
    "1) Өмірге қауіп болса 112/103 нөміріне дереу қоңырау шалыңыз.",
    "2) Қауіпсіз ортаны қамтамасыз етіңіз.",
    "3) Естен тану/қан кету болса алғашқы көмек протоколын қолданыңыз.",
    "4) Симптомдар уақытын және дәрілерді жазып қойыңыз.",
  ],
  domestic_violence: [
    "1) Егер қауіп тікелей болса, 112-ге бірден хабарласыңыз.",
    "2) Қауіпсіз жерге ауысыңыз және сенімді адамға белгі беріңіз.",
    "3) Дәлелдерді сақтаңыз (скрин, фото, медициналық анықтама).",
    "4) Дағдарыс орталығы/сенім телефонына жүгініңіз.",
  ],
  legal: [
    "1) Оқиғаның нақты хронологиясын тіркеңіз.",
    "2) Куәгер контактілерін және материалдарды сақтаңыз.",
    "3) Ресми арыз беру үшін жергілікті органға жүгініңіз.",
    "4) Кәсіби заңгермен кеңесіңіз.",
  ],
  general: [
    "1) Дереу қауіп деңгейін бағалаңыз.",
    "2) Қауіп болса 112-ге хабарласыңыз.",
    "3) Локацияңызды жақын адамға жіберіңіз.",
    "4) Қауіпсіз маршрут пен шығу нүктесін таңдаңыз.",
  ],
};

const detectContext = (text) => {
  const normalized = (text || "").toLowerCase();

  if (/(ұста|задерж|полиц|detain)/i.test(normalized)) return "detention";
  if (/(қан|жара|medic|жедел|103)/i.test(normalized)) return "medical";
  if (/(зорлық|violence|abuse|ұрды)/i.test(normalized)) return "domestic_violence";
  if (/(заң|адвокат|court|сот)/i.test(normalized)) return "legal";

  return "general";
};

const evaluateSafetyFlags = (text) => {
  return SAFETY_TRIGGERS.filter((trigger) => trigger.regex.test(text || "")).map((item) => item.key);
};

const generateSafeResponse = ({ message, context }) => {
  const resolvedContext = context === "general" ? detectContext(message) : context;
  const steps = TEMPLATES[resolvedContext] || TEMPLATES.general;
  const safetyFlags = evaluateSafetyFlags(message);

  const escalation = safetyFlags.length
    ? "Қауіп жоғары көрінеді. Дереу 112 нөміріне хабарласып, жалғыз қалмауға тырысыңыз."
    : null;

  const responseText = [
    escalation,
    "Ұсынылатын қадамдар:",
    ...steps,
    DISCLAIMER,
  ]
    .filter(Boolean)
    .join("\n");

  return {
    responseText,
    safetyFlags,
    context: resolvedContext,
    disclaimer: DISCLAIMER,
  };
};

const sanitizeModelText = (text) => {
  if (!text) {
    return "";
  }

  return text
    .replace(/\*\*/g, "")
    .replace(/```[\s\S]*?```/g, "")
    .trim();
};

const composeFinalResponse = ({ modelText, safeFallbackText, safetyFlags }) => {
  if (!modelText) {
    return safeFallbackText;
  }

  const cleanModel = sanitizeModelText(modelText);
  const escalation = safetyFlags.length
    ? "Қауіп жоғары көрінеді. Егер тікелей қауіп болса, 112-ге бірден хабарласыңыз."
    : null;

  return [escalation, cleanModel, DISCLAIMER].filter(Boolean).join("\n\n");
};

module.exports = {
  generateSafeResponse,
  composeFinalResponse,
  DISCLAIMER,
};
