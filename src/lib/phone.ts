/**
 * Normalises an Indian mobile number to E.164 (+91XXXXXXXXXX).
 * Accepts "98765 43210", "+91-98765-43210", "09876543210", "919876543210".
 * Returns null for anything that is not a valid Indian mobile number.
 */
export function normalizeIndianMobile(input: string): string | null {
  const digits = input.replace(/[\s\-().]/g, "");
  let local: string | null = null;
  if (/^\+91\d{10}$/.test(digits)) local = digits.slice(3);
  else if (/^91\d{10}$/.test(digits)) local = digits.slice(2);
  else if (/^0\d{10}$/.test(digits)) local = digits.slice(1);
  else if (/^\d{10}$/.test(digits)) local = digits;
  if (!local || !/^[6-9]\d{9}$/.test(local)) return null;
  return `+91${local}`;
}

/** "+91 98XXXXXX10" — for display and logs. */
export function maskPhone(e164: string): string {
  return `${e164.slice(0, 3)} ${e164.slice(3, 5)}XXXXXX${e164.slice(-2)}`;
}
