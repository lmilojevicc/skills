# Native desktop and exact-window capture

Use native capture when the operating-system window, native controls, or GPU-rendered surface is the evidence. Prefer an app export or deterministic renderer when it is equivalent.

## Permissions

On macOS, window pixels generally require Screen Recording permission. UI scripting, window enumeration, focus, or automated interaction may also require Accessibility permission. Explain why each permission is needed, request the minimum scope, and stop if denied. Do not attempt permission bypasses or silently broaden scope.

Other platforms have equivalent portal/session permissions. Use the platform's supported window-capture API and make permission state part of the evidence.

## Exact window ownership

A window ID or index is transient. Immediately before capture:

1. launch or connect to the exact app instance you own;
2. verify process ID, bundle/application identity, and expected window title;
3. reject an empty, minimized, hidden, off-screen, unrelated, or ambiguous match;
4. move/resize through supported APIs only when needed, then wait for a stable frame;
5. enumerate again and capture the verified window ID;
6. verify the resulting image dimensions/content before closing the app.

Never capture “frontmost window” without proving what it is. Never use a stale positional index from an earlier enumeration. Exclude notifications, other windows, menu extras, desktop icons, and private wallpaper unless explicitly in scope.

## App state

Use fixture documents/accounts and deterministic content. Freeze clocks, progress, random lists, sync status, and animation. Set appearance, locale, text size, display scale, window content size, sidebars, toolbars, selection, focus, pointer, and scroll position. Account for OS-provided title bars and shadows when calculating exact output dimensions.

Retina/high-DPI captures may be 2× the logical window size. Record both logical points and output pixels; do not silently resample away the distinction.

## Decoration choices

Choose one path and record it:

- **Capture-tool decorators** (for example CleanShot-style background, padding, inset, corner, or shadow controls) are efficient for one-off editorial assets. Pin each setting and tool version. Disable decorative defaults that were not requested.
- **Reproducible local composition** is preferable for checked-in or frequently regenerated assets. Capture raw pixels, then use an explicit compositor command with fixed canvas, outer margin, internal padding, wallpaper crop/dim, rounded mask, and optional shadow.

Do not apply both tool decoration and local decoration accidentally. Shadow is off by default; glow is absent unless explicitly requested. For repeatable assets, keep the raw capture until the composed preview is approved.

## Cleanup

Close only the fixture document/app instance and helper process started for the capture. Remove temporary screenshots and automation files after hashing/publishing the approved artifact. Record any permission prompts or manual steps that prevent fully unattended reproduction.
