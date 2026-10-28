// All scheduling is expressed in India Standard Time (UTC+05:30, no DST) and
// stored as UTC instants. Poll open/close decisions always use server time.

export const IST_OFFSET_MINUTES = 330;
export const TIME_ZONE = "Asia/Kolkata";

/** "YYYY-MM-DD" for the IST calendar day containing `instant`. */
export function istDateString(instant: Date = new Date()): string {
  const shifted = new Date(instant.getTime() + IST_OFFSET_MINUTES * 60_000);
  return shifted.toISOString().slice(0, 10);
}

/** UTC instant for a wall-clock IST date ("YYYY-MM-DD") and time ("HH:MM"). */
export function istToUtc(date: string, time: string): Date {
  if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) throw new Error(`Invalid date: ${date}`);
  if (!/^([01]\d|2[0-3]):[0-5]\d$/.test(time) && time !== "24:00") throw new Error(`Invalid time: ${time}`);
  const [y, m, d] = date.split("-").map(Number);
  const [hh, mm] = time.split(":").map(Number);
  const utcMs = Date.UTC(y, m - 1, d, hh, mm) - IST_OFFSET_MINUTES * 60_000;
  // Reject impossible dates such as 2026-02-30.
  if (new Date(Date.UTC(y, m - 1, d)).toISOString().slice(0, 10) !== date) {
    throw new Error(`Invalid date: ${date}`);
  }
  return new Date(utcMs);
}

/** Adds whole days to a "YYYY-MM-DD" string. */
export function addDays(date: string, days: number): string {
  const [y, m, d] = date.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d + days)).toISOString().slice(0, 10);
}

/** Opening and closing instants for a daily poll. Close "24:00" means end of day. */
export function dailyWindow(date: string, openTime = "00:00", closeTime = "24:00") {
  const opensAt = istToUtc(date, openTime);
  const closesAt = closeTime === "24:00" ? istToUtc(addDays(date, 1), "00:00") : istToUtc(date, closeTime);
  if (closesAt <= opensAt) throw new Error("Closing time must be after opening time");
  return { opensAt, closesAt };
}

/** Date-only value for Prisma @db.Date columns. */
export function dateOnly(date: string): Date {
  return new Date(`${date}T00:00:00.000Z`);
}

export function formatIst(instant: Date, locale: "en" | "te", withDate = true): string {
  return new Intl.DateTimeFormat(locale === "te" ? "te-IN" : "en-IN", {
    timeZone: TIME_ZONE,
    ...(withDate ? { day: "numeric", month: "short", year: "numeric" } : {}),
    hour: "numeric",
    minute: "2-digit",
  }).format(instant);
}

export function formatIstDate(instant: Date, locale: "en" | "te"): string {
  return new Intl.DateTimeFormat(locale === "te" ? "te-IN" : "en-IN", {
    timeZone: TIME_ZONE,
    weekday: "short",
    day: "numeric",
    month: "short",
    year: "numeric",
  }).format(instant);
}
