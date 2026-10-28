// SMS delivery for OTP codes. Choose a provider with SMS_PROVIDER.
// Indian SMS traffic requires a DLT-registered sender and template; configure
// that with your provider before going live.

export interface SmsSender {
  sendOtp(phoneE164: string, code: string): Promise<void>;
}

const message = (code: string) =>
  `${code} is your VoteWala verification code. It expires in 5 minutes. Do not share it with anyone.`;

const consoleSender: SmsSender = {
  async sendOtp(phone, code) {
    if (process.env.NODE_ENV === "production") {
      throw new Error("SMS_PROVIDER=console is not allowed in production");
    }
    console.info(`[sms:console] OTP for ${phone}: ${code}`);
  },
};

const twilioSender: SmsSender = {
  async sendOtp(phone, code) {
    const sid = required("TWILIO_ACCOUNT_SID");
    const token = required("TWILIO_AUTH_TOKEN");
    const from = required("TWILIO_FROM_NUMBER");
    const res = await fetch(`https://api.twilio.com/2010-04-01/Accounts/${sid}/Messages.json`, {
      method: "POST",
      headers: {
        Authorization: `Basic ${Buffer.from(`${sid}:${token}`).toString("base64")}`,
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({ To: phone, From: from, Body: message(code) }),
    });
    if (!res.ok) throw new Error(`Twilio responded ${res.status}`);
  },
};

const msg91Sender: SmsSender = {
  async sendOtp(phone, code) {
    const res = await fetch("https://control.msg91.com/api/v5/otp", {
      method: "POST",
      headers: { authkey: required("MSG91_AUTH_KEY"), "Content-Type": "application/json" },
      body: JSON.stringify({
        template_id: required("MSG91_TEMPLATE_ID"),
        mobile: phone.replace("+", ""),
        otp: code,
      }),
    });
    if (!res.ok) throw new Error(`MSG91 responded ${res.status}`);
  },
};

function required(name: string): string {
  const value = process.env[name];
  if (!value) throw new Error(`${name} is not configured`);
  return value;
}

export function getSmsSender(): SmsSender {
  switch (process.env.SMS_PROVIDER ?? "console") {
    case "twilio":
      return twilioSender;
    case "msg91":
      return msg91Sender;
    case "console":
      return consoleSender;
    default:
      throw new Error(`Unknown SMS_PROVIDER: ${process.env.SMS_PROVIDER}`);
  }
}
