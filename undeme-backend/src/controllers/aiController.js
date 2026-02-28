const AiChatLog = require("../models/AiChatLog");
const User = require("../models/User");
const { generateSafeResponse, composeFinalResponse, DISCLAIMER } = require("../services/aiSafetyService");
const { generateGeminiResponse } = require("../services/geminiService");

exports.chat = async (req, res, next) => {
  try {
    const { message, context } = req.body;

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    const safeResult = generateSafeResponse({ message, context });
    const geminiResult = await generateGeminiResponse({
      message,
      context: safeResult.context,
      safetyFlags: safeResult.safetyFlags,
    });

    const finalResponse = composeFinalResponse({
      modelText: geminiResult.ok ? geminiResult.text : "",
      safeFallbackText: safeResult.responseText,
      safetyFlags: safeResult.safetyFlags,
    });
    const usedFallback = !geminiResult.ok;

    await AiChatLog.create({
      user: req.userId,
      message,
      context: safeResult.context,
      response: finalResponse,
      disclaimerShown: true,
      safetyFlags: safeResult.safetyFlags,
      provider: geminiResult.provider,
      model: geminiResult.model,
      usedFallback,
    });

    return res.json({
      message: finalResponse,
      context: safeResult.context,
      disclaimer: DISCLAIMER,
      safetyFlags: safeResult.safetyFlags,
      provider: geminiResult.provider,
      model: geminiResult.model,
      usedFallback,
    });
  } catch (error) {
    return next(error);
  }
};

exports.history = async (req, res, next) => {
  try {
    const items = await AiChatLog.find({ user: req.userId })
      .sort({ createdAt: -1 })
      .limit(50)
      .select("message response context safetyFlags provider model usedFallback createdAt")
      .lean();

    return res.json({ items });
  } catch (error) {
    return next(error);
  }
};
