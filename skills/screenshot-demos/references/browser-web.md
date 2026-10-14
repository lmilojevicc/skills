# Browser and web captures

Use Playwright when it is already present or acceptable for the project. Prefer the project's existing server and test configuration over a new harness.

## Ownership and cleanup

- Check for an existing Playwright dependency, web server command, base URL, fixtures, and screenshot tests before adding anything.
- If starting a server, bind to `127.0.0.1`, choose or reserve a port, capture its PID, and install cleanup with `trap`. Stop only that PID/process group; never `pkill` a broad name.
- Probe readiness at a specific URL and fail with server logs after a bounded timeout.
- Record server start, readiness, capture, and cleanup evidence.

A shell owner can use this pattern:

```sh
log="${TMPDIR:-/tmp}/screenshot-server.log"
npm run dev -- --host 127.0.0.1 --port 4173 >"$log" 2>&1 &
server_pid=$!
trap 'kill "$server_pid" 2>/dev/null || true; wait "$server_pid" 2>/dev/null || true' EXIT INT TERM
# Poll the exact local URL with a bounded loop, then run the capture.
```

Adapt arguments to the actual project; do not assume every server accepts `--host` or `--port`.

## Stable Playwright capture

Set the viewport explicitly and prefer `deviceScaleFactor: 1` unless the requested artifact needs a documented high-density scale. Load deterministic fixture data and disable live analytics, chat, notifications, clocks, and network-dependent content.

Before capture:

1. Navigate to a local or approved URL and assert the expected route/state.
2. Wait for a product-specific ready marker—not `networkidle` alone on apps with long polling.
3. Wait for `document.fonts.ready` and confirm expected font faces loaded.
4. Decode critical images with `img.decode()` and verify no asset reports `naturalWidth === 0`.
5. Disable animations/transitions before navigation when they affect initial state, or wait for an explicit settled-state marker.
6. Place hover, focus, selection, scroll, popover, and cursor states intentionally.
7. Capture a locator when the component is the subject; capture the page only when page context matters.

Minimal TypeScript shape:

```ts
await page.setViewportSize({ width: 1440, height: 900 });
await page.goto(url, { waitUntil: "domcontentloaded" });
await page.locator("[data-screenshot-ready='true']").waitFor();
await page.evaluate(async () => {
  await document.fonts.ready;
  await Promise.all([...document.images].map((image) => image.decode()));
});
await page.locator("[data-demo-surface]").screenshot({
  path: previewPath,
  animations: "disabled",
  caret: "hide",
});
```

If animations communicate required state, drive them to a fixed timestamp or explicit endpoint rather than accepting a random frame. Never hide content solely to make a screenshot pass unless the resulting state is a real supported state.

## Variants

Build the smallest requested matrix:

- theme: light, dark, or both;
- viewport: exact desktop/mobile sizes requested;
- browser engine only when rendering differences matter;
- device profile only for a real device-specific requirement.

Name files with stable dimensions/state (`dashboard-dark-1440x900.png`). Do not multiply variants by default. Mobile web belongs here; native mobile belongs in the mobile reference.

## Review

Check browser console and failed requests, font identity, image decode, clipping, sticky/fixed overlaps, scrollbars, focus/caret, device scale, and the image at its intended display size. Preserve accessible meaning outside the image when it is destined for a README.
