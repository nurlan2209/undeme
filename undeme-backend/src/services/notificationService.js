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

const normalizePhone = (phone) => {
  if (!phone) {
    return "";
  }
  return String(phone).replace(/[^\d]/g, "");
};

const buildWhatsAppBody = ({ to, message }) => {
  if (env.whatsappTemplateName) {
    return {
      messaging_product: "whatsapp",
      to,
      type: "template",
      template: {
        name: env.whatsappTemplateName,
        language: {
          code: env.whatsappTemplateLanguage,
        },
      },
    };
  }

  return {
    messaging_product: "whatsapp",
    to,
    type: "text",
    text: {
      preview_url: false,
      body: message.slice(0, 4096),
    },
  };
};

const dispatchWebhook = async ({ payload }) => {
  if (!env.sosWebhookUrl) {
    return {
      channel: "webhook",
      success: false,
      error: "SOS_WEBHOOK_URL is not configured",
    };
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

const dispatchWhatsAppBusiness = async ({ contacts, message }) => {
  if (!contacts.length) {
    return {
      channel: "whatsapp_business",
      success: false,
      error: "No emergency contacts configured",
    };
  }

  if (!env.whatsappBusinessToken || !env.whatsappPhoneNumberId) {
    return {
      channel: "whatsapp_business",
      success: false,
      error: "WhatsApp Business credentials are not configured",
    };
  }

  const endpoint = `https://graph.facebook.com/${env.whatsappApiVersion}/${env.whatsappPhoneNumberId}/messages`;

  let sent = 0;
  const errors = [];

  for (const contact of contacts) {
    const to = normalizePhone(contact.phone);
    if (!to) {
      errors.push(`${contact.name || "contact"}: invalid phone`);
      continue;
    }

    try {
      const response = await fetch(endpoint, {
        method: "POST",
        headers: {
          Authorization: `Bearer ${env.whatsappBusinessToken}`,
          "Content-Type": "application/json",
        },
        body: JSON.stringify(buildWhatsAppBody({ to, message })),
      });

      const data = await response.json().catch(() => ({}));
      if (!response.ok) {
        errors.push(`${contact.name || to}: ${data?.error?.message || response.status}`);
        continue;
      }

      sent += 1;
    } catch (error) {
      errors.push(`${contact.name || to}: ${error.message}`);
    }
  }

  return {
    channel: "whatsapp_business",
    success: sent > 0,
    error: sent > 0 ? (errors.length ? errors.join("; ") : null) : errors.join("; "),
  };
};

const sendEmergencyNotifications = async ({ user, reason, location }) => {
  const message = buildMessage({ user, location, reason });

  const payload = {
    type: "sos_alert",
    userId: String(user._id),
    fullName: user.fullName,
    phone: user.phone,
    contacts: user.emergencyContacts,
    reason: reason || "",
    location,
    message,
  };

  const [webhookResult, whatsappResult] = await Promise.all([
    dispatchWebhook({ payload }),
    dispatchWhatsAppBusiness({ contacts: user.emergencyContacts || [], message }),
  ]);

  const attempts = [webhookResult, whatsappResult];
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
