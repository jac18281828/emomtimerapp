//
//  ControlsView.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Media-player "transport deck" of glass keys — built for a sweaty,
//  glance-and-mash workout context rather than precise form entry.
//
//  The transport metaphor carries both adjustable axes:
//    track-skip  (⏮ ⏭) → rounds          (−Rnd / +Rnd)
//    rewind/ff   (◀◀ ▶▶) → interval coarse (−15 / +15)
//    step        (◀ ▶)  → interval fine    (−1  / +1)
//    play/pause  (▶ ❚❚) → start · pause · resume (one toggling key)
//  Below the strip: stop (clear this session) and reset (factory 1:00 × 5).
//
//  Seek keys auto-repeat on press-and-hold (scrub feel); every press gives a
//  haptic tick. Keys reuse the app's liquid-glass styling (Appendix A).
//

import SwiftUI

// MARK: - Key tint

private enum KeyTint {
    case neutral, play, stop

    var fill: LinearGradient {
        let colors: [Color]
        switch self {
        case .neutral:
            colors = [
                Color(red: 0.55, green: 0.78, blue: 1.00).opacity(0.28),
                Color(red: 0.35, green: 0.49, blue: 0.92).opacity(0.28),
                Color(red: 0.27, green: 0.18, blue: 0.63).opacity(0.30),
            ]
        case .play:
            colors = [
                Color(red: 0.52, green: 0.90, blue: 0.66).opacity(0.34),
                Color(red: 0.20, green: 0.66, blue: 0.42).opacity(0.40),
            ]
        case .stop:
            colors = [
                Color(red: 1.00, green: 0.72, blue: 0.64).opacity(0.30),
                Color(red: 0.80, green: 0.28, blue: 0.24).opacity(0.36),
            ]
        }
        return LinearGradient(colors: colors,
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var border: Color {
        switch self {
        case .neutral: Color(red: 0.51, green: 0.69, blue: 1.00).opacity(0.35)
        case .play:    Color(red: 0.30, green: 0.78, blue: 0.50).opacity(0.50)
        case .stop:    Color(red: 0.85, green: 0.40, blue: 0.36).opacity(0.45)
        }
    }

    var foreground: Color {
        switch self {
        case .neutral: Color(hex: 0x283f8a)
        case .play:    Color(red: 0.06, green: 0.36, blue: 0.20)
        case .stop:    Color(red: 0.55, green: 0.15, blue: 0.12)
        }
    }

    var feedbackWeight: SensoryFeedback {
        switch self {
        case .play, .stop: .impact(weight: .medium)
        case .neutral:     .impact(weight: .light)
        }
    }
}

private func keyShape(_ tint: KeyTint) -> some View {
    RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(tint.fill)
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(tint.border, lineWidth: 1)
        )
        .shadow(color: Color(red: 0.14, green: 0.21, blue: 0.55).opacity(0.25),
                radius: 8, x: 0, y: 4)
}

// MARK: - Transport key

/// A chunky glass key: SF Symbol over a small caption, hard press-scale, a
/// haptic per press, and optional press-and-hold auto-repeat (for scrubbing).
private struct DeckKey: View {
    let systemImage: String
    var caption: String? = nil
    var tint: KeyTint = .neutral
    var iconSize: CGFloat = 22
    var repeats: Bool = false
    var repeatInterval: Double = 0.12
    let label: String
    let action: () -> Void

    @State private var pressed = false
    @State private var holding = false
    @State private var pulse = 0

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: systemImage)
                .font(.system(size: iconSize, weight: .semibold))
                .frame(height: iconSize + 2)
            if let caption {
                Text(caption)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .foregroundStyle(tint.foreground)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 11)
        .background(keyShape(tint))
        .scaleEffect(pressed ? 0.90 : 1.0)
        .animation(.easeOut(duration: 0.08), value: pressed)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    guard !pressed else { return }
                    pressed = true
                    fire()
                    if repeats { holding = true }
                }
                .onEnded { _ in
                    pressed = false
                    holding = false
                }
        )
        .task(id: holding) {
            guard holding else { return }
            try? await Task.sleep(for: .seconds(0.4))   // delay before scrub
            while !Task.isCancelled {
                fire()
                try? await Task.sleep(for: .seconds(repeatInterval))
            }
        }
        .sensoryFeedback(tint.feedbackWeight, trigger: pulse)
        .accessibilityElement()
        .accessibilityLabel(label)
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { fire() }
    }

    private func fire() {
        action()
        pulse &+= 1
    }
}

// MARK: - Controls

struct ControlsView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        VStack(spacing: verticalSizeClass == .compact ? 8 : 12) {
            transportStrip
            utilityRow
        }
    }

    // MARK: Transport strip (7 keys: −Rnd ◀◀ ◀ ▶/❚❚ ▶ ▶▶ +Rnd)

    private var transportStrip: some View {
        HStack(spacing: 5) {
            DeckKey(systemImage: "backward.end.fill", caption: "−Rnd",
                    label: "One fewer round") { engine.adjustRounds(-1) }

            DeckKey(systemImage: "backward.fill", caption: "−15",
                    repeats: true, repeatInterval: 0.22,
                    label: "Subtract 15 seconds") { engine.adjustInterval(seconds: -15) }

            DeckKey(systemImage: "chevron.left", caption: "−1",
                    repeats: true, repeatInterval: 0.10,
                    label: "Subtract 1 second") { engine.adjustInterval(seconds: -1) }

            DeckKey(systemImage: engine.isRunning ? "pause.fill" : "play.fill",
                    caption: playCaption, tint: .play, iconSize: 26,
                    label: playCaption) { togglePlay() }

            DeckKey(systemImage: "chevron.right", caption: "+1",
                    repeats: true, repeatInterval: 0.10,
                    label: "Add 1 second") { engine.adjustInterval(seconds: 1) }

            DeckKey(systemImage: "forward.fill", caption: "+15",
                    repeats: true, repeatInterval: 0.22,
                    label: "Add 15 seconds") { engine.adjustInterval(seconds: 15) }

            DeckKey(systemImage: "forward.end.fill", caption: "+Rnd",
                    label: "One more round") { engine.adjustRounds(1) }
        }
    }

    // MARK: Utility row (stop / reset)

    private var utilityRow: some View {
        HStack(spacing: 10) {
            DeckKey(systemImage: "stop.fill", caption: "Stop", tint: .stop, iconSize: 18,
                    label: "Stop and clear this session") { engine.stop() }
                .frame(maxWidth: 120)

            DeckKey(systemImage: "arrow.counterclockwise", caption: "Reset", iconSize: 18,
                    label: "Reset to one minute, five rounds") { engine.reset() }
                .frame(maxWidth: 120)
        }
    }

    private var playCaption: String {
        switch engine.phase {
        case .running: "Pause"
        case .paused:  "Resume"
        case .idle:    "Start"
        }
    }

    private func togglePlay() {
        if engine.isRunning { engine.pause() } else { engine.start() }
    }
}
