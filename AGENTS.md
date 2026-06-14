# AI Contributing Requirements

These rules apply to all AI-assisted changes in this repository.

## Project Overview

A fully native, fully offline SwiftUI iOS app — an EMOM (Every Minute on the Minute) workout timer ported from the Rust/WASM web app in the sister repo. No network dependency at runtime. iOS 17+, bundle ID `com.emomtimer.app`.

Key source layout:
```
EMOMTimer/
├── EMOMApp.swift          — @main; injects TimerEngine; wires scenePhase
├── Engine/
│   ├── TimerPhase.swift   — enum: idle, running, paused
│   ├── ColorCue.swift     — enum: none, green, red (Equatable)
│   ├── CueLogic.swift     — pure functions: colorCue(R:r:t:round:), decompose(remaining:)
│   └── TimerEngine.swift  — @Observable; wall-clock timing, all intents, effect-firing
├── Services/
│   ├── AudioCuePlayer.swift — AVAudioEngine + synthesized beeps (no bundled assets)
│   ├── Haptics.swift        — UIImpactFeedbackGenerator wrapper
│   └── ScreenWake.swift     — isIdleTimerDisabled toggling
└── Views/
    ├── ContentView.swift          — full-screen layout; scenePhase → handleForeground()
    ├── LiquidGlassBackground.swift — animated gradient + cloud blobs + GlassCard struct
    ├── TimerDisplayView.swift     — large M:SS.t, colour cues, tenths pulse, idle breathe
    ├── RoundsView.swift           — current/total + interval + hairline divider
    └── ControlsView.swift         — 9 glass buttons; GlassButtonStyle; portrait/landscape
```

**Timing model:** wall-clock only — `remaining = intervalDuration - Date().timeIntervalSince(roundStartDate)`. Phase-locked round advance (`roundStartDate += intervalDuration`). No tick accumulation.

## Sister Repository

The web app this iOS app was ported from lives at `~/src/emomtimer`. Consult it when working on anything that touches domain behaviour or visual design.

**Tech stack:** Rust → WebAssembly via Yew 0.22 and Trunk. No JavaScript framework.

**Domain model (in `src/lib.rs`):**
- `Timer` — current_time, rounds, current_round, running state
- `Time` — minutes / seconds / tenths-of-seconds (ticks are 100 ms)
- Default workout: 1 minute, 5 rounds

**Visual feedback:** blink states (Red at round end, Green at round start) and a liquid-glass aesthetic (animated gradient, cloud layer, glass card). The iOS port reproduces these natively.

**Sister repo completion gates** (run there, not here, when changing the web app):
```
cargo check
cargo fmt --all -- --check
cargo clippy --all-targets --all-features --no-deps -- -D warnings
cargo test
trunk build --release
```

## Workflow
1. Read every file you plan to change and directly related modules.
2. Summarize current behavior and the invariants that must be preserved.
3. Propose a minimal patch plan (diff and rationale).
4. Obtain user approval before editing code.
5. Affirm all `Completion Gates` are met.

## Code Design
- Prioritize correctness, then idiomatic and reviewable Swift/SwiftUI.
- Prefer clarity over cleverness.
- Write small single-purpose types and functions with clear names.
- Keep `@Observable` classes thin on the view side: views are pure renderers, the engine owns all state.
- `CueLogic` and `TimerPhase`/`ColorCue` are pure and must stay UI-free so they can be unit-tested without a simulator.
- Prefer decomposition over accretion: extract helpers as behaviour grows.
- Keep diffs focused; avoid idiosyncratic churn.
- Write comments that explain enduring intent or constraints, not editorial commentary.

## Naming
- Naming must be semantic.
- Do not encode type or structural primitives in names.
- Avoid namespace prefixes or suffixes.

## Key Invariants
- `TimerEngine.processFrame()` must never fire audio or haptics for round boundaries skipped while the app was in the background — only for boundaries crossed in real time (the `boundariesCrossed == 1` guard).
- `CueLogic.colorCue(R:r:t:round:)` is the single source of truth for colour cues. Do not replicate its logic elsewhere.
- `roundStartDate` advances by exactly `intervalDuration` per boundary (phase-lock) — do not set it to `Date()` on round rollover.
- Audio session category is `.playback + .mixWithOthers`: beeps are audible on silent and play alongside the user's music.
- `UIApplication.isIdleTimerDisabled` must be `true` while running and restored to `false` on pause/stop/finish.

## Dependencies and Imports
- Prefer the standard library and system frameworks (SwiftUI, AVFoundation, UIKit, Observation).
- Add external packages only with user approval.
- Declare imports at the top of each file; keep them explicit.
- Respect the iOS 17.0 deployment target: do not use APIs newer than iOS 17 without a version guard.

## Tests
- `CueLogic` and `TimerPhase`/`ColorCue` are pure and should be unit-tested without a simulator.
- Port the `update_blink_state` tests from Appendix D of `IMPLEMENTATION_PROMPT.md` verbatim — they define the exact colour-cue contract.
- Unit tests must be hermetic: no network, no real AVAudioEngine, no real UIApplication, no wall-clock dependencies.
- Add or update tests for every behaviour change.

## Completion Gates

Before marking work complete, run and report:

1. `xcodebuild -project EMOMTimer.xcodeproj -scheme EMOMTimer -destination 'generic/platform=iOS' build` — project compiles cleanly
2. `xcodebuild -project EMOMTimer.xcodeproj -scheme EMOMTimer -destination 'platform=iOS Simulator,name=iPhone 16' test` — all tests pass (if a test target exists)
3. For UI-visible changes: launch on simulator or device and verify the golden path:
   - Default 1:00 × 5 starts, counts down, advances through all 5 rounds
   - Green cue fires for first 3 s of rounds 2–5; red cue + countdown beep for last 3 s of every round
   - Boundary beep + haptic fires at each round-to-round transition
   - Screen stays awake while running; idle timer restored on pause/finish
   - Music from another app continues to play under beeps
   - ±1/±15 interval adjustment and ±Rnd work while running and paused
   - Reset returns to 1:00 × 5
   - Portrait and landscape on iPhone and iPad: clean layout, no digit jitter

Do not mark work complete until all applicable gates pass.
