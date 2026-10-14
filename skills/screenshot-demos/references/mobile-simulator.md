# Mobile and simulator captures

Use this route for native mobile interfaces in iOS Simulator, Android Emulator, or a controlled physical device. Mobile web stays on the browser route.

## Prefer simulators/emulators

Use an installed simulator/emulator and the project's existing UI-test or demo configuration. Physical-device capture is appropriate only when hardware behavior is the subject or a simulator cannot represent the UI. Do not ask for SDK or emulator installation until checking the repository and installed tools.

Pin and record:

- platform/runtime version, device model, orientation, pixel density, and appearance;
- app build/configuration and source revision/state;
- locale, time zone, 12/24-hour clock, text size, display zoom, and accessibility settings;
- status/navigation bar policy, keyboard visibility, pointer/touch indicators, safe areas, and permissions;
- deterministic fixture data, network state, and seeded storage.

## Stable state

Boot one named device you own, install the intended build, reset only the app's fixture state, and navigate via a deterministic deep link or UI-test path. Wait on a semantic ready condition: visible element, idle transition, completed image decode, or app-specific test signal. Fixed sleeps alone are fragile.

Normalize or intentionally show system chrome. If status bars are visible, avoid real carrier/device names, notification indicators, personal VPN state, and live time. Never crop away safe-area behavior that is part of the product evidence.

## Capture and variants

Use the platform's screenshot command/API for the exact booted device, not a host-screen crop. Verify portrait/landscape dimensions and density. Capture only the requested theme/device matrix; one representative device is the default.

Device frames are third-party assets and can misrepresent hardware. Add them only when requested, preserve the screenshot aspect ratio, use a licensed frame, and record credit. For README product evidence, an unframed native screenshot is often clearer and more reproducible.

## Privacy and cleanup

Use synthetic accounts, contacts, photos, locations, messages, health data, and push payloads. Check keyboards, share sheets, autofill, notification center, status indicators, and recent-app thumbnails. Shut down or retain the simulator according to project policy; delete temporary captures and fixture credentials, and report cleanup evidence.
