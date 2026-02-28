const env = require("../config/env");

const GEMINI_API_BASE = "https://generativelanguage.googleapis.com/v1beta";

const buildModelCandidates = () => {
  const models = [env.geminiModel, "gemini-3-flash-preview"];
  return [...new Set(models.filter(Boolean))];
};

const buildPrompt = ({ message, context, safetyFlags }) => {
  const safetyBlock = safetyFlags.length
    ? `Safety flags: ${safetyFlags.join(", ")}. Prioritize immediate emergency guidance.`
    : "No high-risk safety flags detected.";

  return [
    "You are Undeme Safety Assistant.",
    "Answer in clear Kazakh language.",
    "Avoid legal certainty claims and avoid hallucinations.",
    "If user is in immediate danger, first line must instruct to call 112.",
    "Format response with short numbered actions only.",
    `Context: ${context}`,
    safetyBlock,
    `User message: ${message}`,
  ].join("\n");
};

const extractText = (payload) => {
  const candidates = payload?.candidates;
  if (!Array.isArray(candidates) || !candidates.length) {
    return "";
  }

  const parts = candidates[0]?.content?.parts;
  if (!Array.isArray(parts)) {
    return "";
  }

  return parts
    .map((part) => part?.text || "")
    .filter(Boolean)
    .join("\n")
    .trim();
};

const callGeminiModel = async ({ model, prompt }) => {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);

  try {
    const response = await fetch(
      `${GEMINI_API_BASE}/models/${encodeURIComponent(model)}:generateContent?key=${encodeURIComponent(env.geminiApiKey)}`,
      {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        signal: controller.signal,
        body: JSON.stringify({
          contents: [{ parts: [{ text: prompt }] }],
          generationConfig: {
            temperature: 0.3,
            topK: 20,
            topP: 0.9,
            maxOutputTokens: 500,
          },
        }),
      }
    );

    const payload = await response.json().catch(() => ({}));

    if (!response.ok) {
      return {
        ok: false,
        error: payload?.error?.message || `Gemini HTTP ${response.status}`,
      };
    }

    const text = extractText(payload);
    if (!text) {
      return { ok: false, error: "Gemini returned empty response" };
    }

    return { ok: true, text };
  } catch (error) {
    return { ok: false, error: error.message };
  } finally {
    clearTimeout(timeout);
  }
};

const generateGeminiResponse = async ({ message, context, safetyFlags }) => {
  if (!env.geminiApiKey) {
    return {
      ok: false,
      error: "GEMINI_API_KEY is not configured",
      provider: "local_safe_fallback",
      model: null,
    };
  }

  const prompt = buildPrompt({ message, context, safetyFlags });
  const models = buildModelCandidates();

  for (const model of models) {
    const result = await callGeminiModel({ model, prompt });
    if (result.ok) {
      return {
        ok: true,
        text: result.text,
        provider: "gemini",
        model,
      };
    }
  }

  return {
    ok: false,
    error: "All Gemini model candidates failed",
    provider: "local_safe_fallback",
    model: null,
  };
};

module.exports = {
  generateGeminiResponse,
};
