---
name: yt-dlp-stealth
description: "Run yt-dlp on YouTube in stealth (incognito) mode — get past 'Sign in to confirm you're not a bot' walls, HTTP 429 rate limits, and IP-flagged bot checks without cookies or accounts. Use whenever a YouTube fetch with yt-dlp fails with bot-check errors, 429s, LOGIN_REQUIRED playability, or 'No request handlers configured', or when the user asks for anonymous/incognito YouTube downloads."
license: MIT
metadata:
  version: "1.0.0"
---

# yt-dlp Stealth Mode

YouTube aggressively blocks flagged IPs with the **"Sign in to confirm you're not a bot"** wall and **HTTP 429** rate limits. Stealth mode gets around this without cookies or accounts by combining a **Proof-of-Origin Token (POT) provider** with the right **client + visitor data**.

## When to use

- yt-dlp YouTube errors: "Sign in to confirm you're not a bot", HTTP 429 Too Many Requests, `LOGIN_REQUIRED` playability, "No request handlers configured"
- Any anonymous YouTube download / subtitle fetch where the user doesn't want to touch browser cookies
- **Don't** reach for it when cookies are already configured and working — stealth is the fallback for flagged IPs

## Architecture (3 layers)

1. **POT provider server** — generates proof-of-origin tokens that make your traffic look like a real browser. Runs from the upstream `bgutil-ytdlp-pot-provider` checkout, wherever the user installed it.
2. **yt-dlp plugin** — fetches tokens from the server and injects them into YouTube requests. Lives in yt-dlp's site-packages as `yt_dlp_plugins/extractor/getpot_*.py` (or a zip in the plugin dir).
3. **Client + visitor data** — `player_client=web_safari` with a fresh visitor_data defeats the bot check that the default `web` client trips.

## The sequence

### 1. Check the POT server is running

```bash
curl -s http://127.0.0.1:4416/ping
```

Expect `{"server_uptime":...,"version":"1.3.1"}`. If it's empty or refused, set the provider checkout directory and start the server (as a background process, not shell `&`):

```sh
POT_PROVIDER_DIR='/path/to/bgutil-ytdlp-pot-provider' # Replace with the checkout directory.
: "${POT_PROVIDER_DIR:?Set POT_PROVIDER_DIR to the provider checkout directory}"

cd "$POT_PROVIDER_DIR/server/node_modules" && \
  deno run --allow-env --allow-net --allow-ffi=. --allow-read=. ../src/main.ts
```

- The **Deno** path runs the TS source directly — no build step. Requires Deno >= 2.
- The **Node** path needs a build first. Using the same `POT_PROVIDER_DIR` value:

  ```sh
  : "${POT_PROVIDER_DIR:?Set POT_PROVIDER_DIR to the provider checkout directory}"
  cd "$POT_PROVIDER_DIR/server" && \
    npm ci && npx tsc && node build/main.js
  ```

  Requires Node >= 22. A stock Node 18 will fail with `ERR_UNKNOWN_FILE_EXTENSION` on the `.ts` source.

### 2. Verify the plugin can see the server

```bash
yt-dlp -v --skip-download <URL> 2>&1 | grep "PO Token Providers"
```

- `bgutil:http-1.3.1 (external)` present → good
- `PO Token Providers: none` → server down or plugin not loaded

### 3. Apply the stealth flags

```bash
--extractor-args "youtube:player_client=web_safari;youtube:visitor_data=<DATA>"
```

- **visitor_data**: the plugin generates one and caches it in `~/.cache/bgutil-ytdlp-pot-provider/cache.json`. Reuse a valid one from the cache, or pass any string and let it regenerate. The warning *"Missing required Visitor Data. You may need to pass Visitor Data with --extractor-args 'youtube:visitor_data=XXX'"* means one is required.
- Multiple extractor args go in one `--extractor-args` flag, joined with `;`.
- If `web_safari` alone still trips the check, try `android_vr`, `tv`, or `mweb` clients.

### 4. Sanity check

```bash
yt-dlp --skip-download --print "%(title)s" <URL> [stealth flags]
```

Title prints without bot errors → stealth is working. Debug lines `[pot:bgutil:http] Generating a gvs PO Token ... Retrieved a gvs PO Token` confirm the POT flow ran.

## Known limitations (important)

- **`web_safari` client = subtitles + images only.** YouTube forces SABR streaming for it, so real video/audio formats are skipped ("Some web_safari client https formats have been skipped as they are missing a URL"). For actual media downloads, switch client (`android`, `ios`, etc.) or use cookies.
- **HTTP 429 on the initial webpage download is tolerable** — it's only a warning; yt-dlp falls back to the API and player endpoints. Ignore it as long as the final fetch succeeds.
- Stealth defeats bot checks, **not** paywalls or age gates. Members-only / login-required content still needs cookies.
- POT tokens expire; the server and cache handle regeneration automatically.

## Troubleshooting cheatsheet

| Symptom | Cause | Fix |
|---|---|---|
| "Sign in to confirm you're not a bot" | POT flow failed / server down | check `/ping`, start server, retry; pass `visitor_data` |
| "PO Token Providers: none" | server unreachable | start server (step 1) |
| "No request handlers configured" | default client has no POT support | use `player_client=web_safari` |
| "Missing required Visitor Data" | visitor_data needed | pass `youtube:visitor_data=...` |
| 429s but fetch eventually succeeds | rate limit on webpage | ignore, it falls back |
| Only storyboard / `sb*` formats listed | web_safari SABR streaming | switch client for real media |
