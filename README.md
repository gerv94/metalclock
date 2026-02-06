# MetalClock (macOS)

A minimalist floating analog clock for macOS 13+ rendered entirely with Metal inside an `MTKView` hosted by SwiftUI. The window is borderless, transparent, and can live as a menu bar (tray) app with optional always-on-top behavior. The clock hands sweep smoothly using high‑resolution time and SDF-based rendering in the Metal fragment shader.

## Features
- **Metal rendering** via `MTKView` hosted in SwiftUI (`NSViewRepresentable`)
- **Transparent, borderless window** with circular hit-testing
- **Menu bar (tray) app** with Show/Hide and Quit
- **Smooth continuous motion** (sweep second hand)
- **SDF + fwidth AA** for crisp edges
- **Layered composition** with subtle hand shadows and per‑layer colors
- **Focus-based window opacity** (alpha changes via `NSWindow.alphaValue`)

## Requirements
- macOS 13+ (Sonoma compatible)
- Xcode 15+ (or compatible with macOS 13 SDK)

## Build & Run
1. Open the project: `MetalClock.xcodeproj`
2. Select the **MetalClock** scheme
3. Choose **My Mac** as the destination
4. Build and Run

The app appears as a floating circular clock window and a menu bar icon (tray) for show/hide and quit.

## Project Structure
- `MetalClock/MetalClockApp.swift` — App entry point
- `MetalClock/AppDelegate.swift` — Window setup, menu bar item, focus opacity
- `MetalClock/ContentView.swift` — SwiftUI wrapper for the Metal view
- `MetalClock/MetalClockView.swift` — `NSViewRepresentable` bridge to `MTKView`
- `MetalClock/ClockMetalView.swift` — Custom `MTKView` (hit testing, drag)
- `MetalClock/MetalRenderer.swift` — Metal pipeline + uniforms + draw loop
- `MetalClock/Shaders/ClockShaders.metal` — Procedural SDF clock rendering

## Customization
### Clock size
- `MetalClock/ContentView.swift` — `clockSize`
- `MetalClock/AppDelegate.swift` — `windowSize`

### Window behavior
- Always-on-top: `window.level = .floating` in `MetalClock/AppDelegate.swift`
- Shadow: `window.hasShadow = false` (set to `true` for subtle shadow)
- Focus opacity: `windowDidBecomeKey` / `windowDidResignKey` in `AppDelegate`
- Ignore mouse when unfocused: `window.ignoresMouseEvents = true`

### Colors & styling
- `MetalClock/Shaders/ClockShaders.metal` — per-layer colors and alpha
  - `ringLayer`, `tickLayer`, `hourLayer`, `minuteLayer`, `secondLayer`, `capLayer`
- Change hand lengths/widths and tick/ring thickness in the shader

### Antialiasing
- SDF AA uses `fwidth()` in the shader for resolution‑independent crisp edges
- MSAA is enabled in `ClockMetalView` via `sampleCount = 4`

## Notes
- Background transparency is controlled by `NSWindow.isOpaque = false` and `backgroundColor = .clear`.
- The shader outputs fully transparent pixels where there’s no clock content.
- All compositing is done in the shader using explicit “over” compositing per layer.

## Troubleshooting
- If the clock is invisible, verify Metal is supported and the window is not hidden via the tray menu.
- If your machine only shows a Dock icon, ensure `NSApp.setActivationPolicy(.accessory)` is set in `AppDelegate`.

## License
This project is provided as-is for personal or educational use.
