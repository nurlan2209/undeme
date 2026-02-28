const SosEvent = require("../models/SosEvent");
const User = require("../models/User");
const env = require("../config/env");
const { sendEmergencyNotifications } = require("../services/notificationService");

const buildAttemptHistory = (attempts) =>
  attempts.map((attempt) => ({
    at: new Date(),
    channel: attempt.channel,
    success: attempt.success,
    error: attempt.error,
  }));

exports.triggerSos = async (req, res, next) => {
  try {
    const { reason, location, force } = req.body;

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    if (!force) {
      const latestEvent = await SosEvent.findOne({ user: req.userId }).sort({ createdAt: -1 });
      if (latestEvent) {
        const diffMs = Date.now() - latestEvent.createdAt.getTime();
        const cooldownMs = env.sosCooldownSeconds * 1000;
        if (diffMs < cooldownMs) {
          return res.status(429).json({
            message: `SOS тым жиі жіберілуде. ${Math.ceil((cooldownMs - diffMs) / 1000)} сек күтіңіз`,
          });
        }
      }
    }

    const sosEvent = new SosEvent({
      user: req.userId,
      reason: reason || "",
      location,
      recipientsCount: user.emergencyContacts.length,
      status: "queued",
    });

    const dispatchResult = await sendEmergencyNotifications({ user, reason, location });

    sosEvent.status = dispatchResult.status;
    sosEvent.attempts = buildAttemptHistory(dispatchResult.attempts);
    sosEvent.dispatchedAt = dispatchResult.dispatchedAt;

    await sosEvent.save();

    return res.status(201).json({
      message: "SOS өңделді",
      event: {
        id: sosEvent._id,
        status: sosEvent.status,
        attempts: sosEvent.attempts,
        dispatchedAt: sosEvent.dispatchedAt,
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports.retrySos = async (req, res, next) => {
  try {
    const { eventId } = req.body;

    const user = await User.findOne({ _id: req.userId, isDeleted: false });
    if (!user) {
      return res.status(404).json({ message: "Пайдаланушы табылмады" });
    }

    const sosEvent = await SosEvent.findOne({ _id: eventId, user: req.userId });
    if (!sosEvent) {
      return res.status(404).json({ message: "SOS оқиғасы табылмады" });
    }

    const dispatchResult = await sendEmergencyNotifications({
      user,
      reason: sosEvent.reason,
      location: sosEvent.location,
    });

    sosEvent.status = dispatchResult.status;
    sosEvent.attempts.push(...buildAttemptHistory(dispatchResult.attempts));
    sosEvent.dispatchedAt = dispatchResult.dispatchedAt;
    await sosEvent.save();

    return res.json({
      message: "SOS қайта жіберілді",
      event: {
        id: sosEvent._id,
        status: sosEvent.status,
        attempts: sosEvent.attempts,
        dispatchedAt: sosEvent.dispatchedAt,
      },
    });
  } catch (error) {
    return next(error);
  }
};

exports.getSosHistory = async (req, res, next) => {
  try {
    const items = await SosEvent.find({ user: req.userId })
      .sort({ createdAt: -1 })
      .limit(20)
      .lean();

    return res.json({ items });
  } catch (error) {
    return next(error);
  }
};
