# Brand assets

Place the official VoteWala logo here as **`brand/VW.png`**. It is the only
source of truth for the logo; nothing in the site redraws it.

`npm run brand` (run automatically by `npm run dev` and `npm run build`) generates:

| Output | Use |
| --- | --- |
| `public/brand/votewala-logo.png` | Header, footer, sign-in, loading and welcome screens. Original artwork cropped of surrounding whitespace only. |
| `public/brand/votewala-logo-transparent.png` | Same crop with the outer background made transparent (edge-connected background only, so white areas inside the artwork are kept). |
| `public/brand/votewala-mark.png` | The symbol (V/W + ballot box + checkmark) cropped from the logo. |
| `src/app/favicon.ico`, `src/app/icon.png`, `src/app/apple-icon.png`, `public/brand/icon-*.png` | Favicon, app and PWA icons made from the symbol crop, scaled without distortion. |
| `src/styles/brand-tokens.css` | Brand orange, green and navy **sampled from the logo**. The suggested tokens (#F36C13, #159447, #14233D) are used only for colours not found in it. |
| `src/styles/brand-meta.json` | Logo dimensions, symbol crop and sampled colours. |

The symbol for the icons is detected automatically: it's the first separate block
of artwork, either left of the wordmark or above it. If the detection picks the wrong region, create
`brand/crop.json` with the crop in original-image pixels and re-run `npm run brand`:

```json
{ "left": 120, "top": 80, "width": 420, "height": 420 }
```

`npm run build` fails when `brand/VW.png` is missing, so the site can never ship
with a substitute logo. `brand-tokens.css` and `brand-meta.json` are committed so
type-checking works without the logo; re-commit them after running `npm run brand`
with the real file.
