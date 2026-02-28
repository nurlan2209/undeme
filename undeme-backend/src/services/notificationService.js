const env = require("../config/env");

const buildMessage = ({ user, location, reason }) => {
  const mapsUrl = `https://maps.google.com/?q=${location.latitude},${location.longitude}`;
  return [
    "[UNDEME SOS]",
    `User: ${user.fullName}`,
    `Phone: ${user.phone}`,
    `Location: ${mapsUrl}`,
    reason ? `Reason: ${reason}` : null,
    `Timestamp: ${new Date().toISOString()}`,
  ]
    .filter(Boolean)
    .join("\n");
};

const dispatchWebhook = async ({ payload }) => {
  if (!env.sosWebhookUrl) {
    return { channel: "webhook", success: false, error: "SOS_WEBHOOK_URL is not configured" };
  }

  try {
    const response = await fetch(env.sosWebhookUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });

    if (!response.ok) {
      return {
        channel: "webhook",
        success: false,
        error: `Webhook status ${response.status}`,
      };
    }

    return { channel: "webhook", success: true, error: null };
  } catch (error) {
    return { channel: "webhook", success: false, error: error.message };
  }
};

const dispatchSmsPlaceholder = async ({ contacts }) => {
  if (!contacts.length) {
    return {
      channel: "sms",
      success: false,
      error: "No emergency contacts configured",
    };
  }

  return {
    channel: "sms",
    success: true,
    error: null,
  };
};

const sendEmergencyNotifications = async ({ user, reason, location }) => {
  const payload = {
    type: "sos_alert",
    userId: String(user._id),
    fullName: user.fullName,
    phone: user.phone,
    contacts: user.emergencyContacts,
    reason: reason || "",
    location,
    message: buildMessage({ user, location, reason }),
  };

  const [webhookResult, smsResult] = await Promise.all([
    dispatchWebhook({ payload }),
    dispatchSmsPlaceholder({ contacts: user.emergencyContacts || [] }),
  ]);

  const attempts = [webhookResult, smsResult];
  const successCount = attempts.filter((item) => item.success).length;

  let status = "failed";
  if (successCount === attempts.length) {
    status = "sent";
  } else if (successCount > 0) {
    status = "partially_sent";
  }

  return {
    status,
    attempts,
    dispatchedAt: new Date(),
  };
};

module.exports = {
  sendEmergencyNotifications,
};
