import Image from "next/image";
import rawMeta from "@/styles/brand-meta.json";

type BrandMeta =
  | { present: false }
  | { present: true; logo: { width: number; height: number }; sha256: string };

const meta = rawMeta as BrandMeta;

/**
 * The official VoteWala logo (brand/VW.png), shown exactly as supplied —
 * cropped of surrounding whitespace only, never redrawn or re-coloured.
 */
export function Logo({
  height,
  className = "",
  priority = false,
  transparent = false,
}: {
  height: number;
  className?: string;
  priority?: boolean;
  transparent?: boolean;
}) {
  if (!meta.present) {
    // Development-only notice. `npm run build` refuses to build without the logo.
    return (
      <span
        className={`inline-flex items-center rounded-md border border-dashed border-brand-orange px-2 text-[11px] font-semibold text-brand-orange-ink ${className}`}
        style={{ height }}
        role="img"
        aria-label="VoteWala"
      >
        Add brand/VW.png
      </span>
    );
  }
  const width = Math.round((height * meta.logo.width) / meta.logo.height);
  return (
    <Image
      src={transparent ? "/brand/votewala-logo-transparent.png" : "/brand/votewala-logo.png"}
      alt="VoteWala — Your Voice. Your Choice."
      width={width}
      height={height}
      priority={priority}
      className={`h-auto max-w-full select-none ${className}`}
      style={{ height, width: "auto" }}
      draggable={false}
    />
  );
}
