# Validation, privacy, and provenance

Approval and evidence are part of the artifact, not an optional finishing step.

## Approval gate

Create a fresh preview path that cannot collide with a published asset. Show the complete composed image at 100% and at the exact README/site display size. Obtain explicit approval before any overwrite. If feedback changes the image, create another preview; do not mutate the previously approved file silently.

## Mechanical validation

For each final candidate, record:

- format, exact pixel width/height, color space, and channels;
- file bytes against the repository/host limit;
- alpha presence and alpha extrema when transparency is required;
- metadata/profiles after deliberate stripping;
- SHA-256 of the exact file;
- source-to-display size and aspect comparison;
- command/config, input hashes, tool versions, and source revision/state.

Use the bundled helper when ImageMagick 7 is available:

```sh
./scripts/validate-image.sh --image /tmp/product-preview.png \
  --expect-width 1600 --expect-height 900 \
  --expect-display 800x450 --require-alpha --max-bytes 2500000
```

A transparent channel is insufficient if every pixel is opaque; the helper checks alpha extrema. Extrema alone do not prove correct extraction: sample/inspect outer margin, internal padding, keyed source background, glyph/cursor, and styled-surface pixels. The first three should expose canvas/base alpha as designed; foreground evidence must remain fully opaque. On a wallpaper version, confirm the wallpaper visibly contributes beneath base pixels while the final output is exact-size and fully opaque. A wallpaper-backed image should normally use `--forbid-alpha` only if the publishing contract requires no alpha.

## Visual validation

Inspect both 100% pixels and actual display size:

- no clipping, unintended scrollbars, truncation, overlap, or cut shadows;
- no tofu/missing icons, font fallback, broken box drawing, or faux weights;
- intentional cursor/caret, hover, focus, selection, keyboard, and scroll states;
- stable content, no skeletons/spinners/toasts or half-finished animation;
- expected truecolor, contrast, fractional base alpha, opaque foreground evidence, rounded mask, and wallpaper dim;
- no keyed holes in glyphs, cursor, icons, antialiased edges, or intentional same-color surfaces;
- preserved aspect ratio and correct outer margin versus internal padding;
- no unrequested glow/shadow/chrome/device frame;
- readable details and meaningful alt text/caption outside the image.

## Privacy review

Review every visible region and OCR-like text manually. Remove:

- credentials, API keys, cookies, QR codes, tokens, recovery codes, and internal IDs;
- real names, emails, avatars, customer data, messages, files, contacts, and photos;
- home paths, usernames, hostnames, IPs, private URLs, branches, shell history, clipboard/autofill suggestions;
- notifications, menu-bar/tray details, calendar/time/location clues, tabs, bookmarks, recent items, and unrelated windows;
- EXIF location/device data, comments, embedded thumbnails, ICC/XMP/IPTC profiles not deliberately retained.

Use fixture data instead of blur where practical; blur can be reversible or leave context. Keep secrets out of commands and environment dumps used as provenance.

## Provenance and credits

Store or report:

- capture date (in provenance notes, not embedded metadata unless required);
- source revision/state and fixture identifier;
- capture and composition commands/config files;
- OS/runtime, renderer, font, ImageMagick, browser/simulator, and decorator versions;
- SHA-256 for raw inputs and final output when reproducibility matters;
- third-party wallpaper, font, icon, device-frame, and stock asset source/license/credit;
- manual steps and known sources of nondeterminism.

Do not imply that generated fixture data is real product/customer evidence. Do not publish third-party assets whose license is unknown.

## Cleanup evidence

Report that owned servers, apps, simulators, and helper processes stopped; temporary inputs/previews/logs were removed or intentionally retained; and no published file changed before approval. Capture process ownership/PIDs where relevant. Never use broad cleanup commands that could terminate unrelated work.
