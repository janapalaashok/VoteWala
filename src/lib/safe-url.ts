/** Only allow same-site relative redirect targets. */
export function safeCallback(url: string | undefined | null, fallback = "/"): string {
  if (!url || typeof url !== "string") return fallback;
  if (!url.startsWith("/") || url.startsWith("//") || url.startsWith("/\\")) return fallback;
  return url;
}
