/* eslint-disable @next/next/no-img-element */
// Candidate photos come from official sources on arbitrary hosts, so a plain
// <img> is used. Without a photo we show initials — never a party symbol.
export function CandidateAvatar({ name, photoUrl, size = 48 }: { name: string; photoUrl: string | null; size?: number }) {
  const words = name.replace(/\(.*?\)/g, "").split(/\s+/).filter(Boolean);
  const initials = (words.length > 1 ? words[0][0] + words[words.length - 1][0] : (words[0] ?? "?").slice(0, 2)).toUpperCase();
  if (photoUrl) {
    return (
      <img
        src={photoUrl}
        alt=""
        width={size}
        height={size}
        loading="lazy"
        referrerPolicy="no-referrer"
        className="shrink-0 rounded-full border border-line bg-page object-cover"
        style={{ width: size, height: size }}
      />
    );
  }
  return (
    <span
      aria-hidden
      className="flex shrink-0 items-center justify-center rounded-full bg-brand-navy/[0.06] font-bold text-brand-navy"
      style={{ width: size, height: size, fontSize: size * 0.36 }}
    >
      {initials}
    </span>
  );
}
