//
//  TimerDisplayView.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Large M:SS.t timer display with colour cues, tenths pulse, idle breathing,
//  and soft white glow — all mirroring the CSS in Appendix A.
//

import SwiftUI

struct TimerDisplayView: View {
    @Environment(TimerEngine.self) private var engine

    // Tenths-digit continuous pulse: scale 1.0↔1.02, opacity 1.0↔0.95, 0.25 s
    @State private var tenthsScale:   CGFloat = 1.0
    @State private var tenthsOpacity: Double  = 1.0

    // Idle breathing: whole display scale 1.0↔1.01, 4 s
    @State private var breatheScale: CGFloat  = 1.0

    var body: some View {
        let cueColor = engine.colorCue.timerColor
        let (r, t)   = CueLogic.decompose(remaining: engine.displayRemaining)
        let m = r / 60
        let s = r % 60

        HStack(alignment: .center, spacing: 0) {
            Text("\(m)")
                .foregroundColor(cueColor)
            Text(":")
                .foregroundColor(cueColor.opacity(0.8))
            Text(String(format: "%02d", s))
                .foregroundColor(cueColor)
            Text(".")
                .foregroundColor(cueColor.opacity(0.8))
            Text("\(t)")
                .foregroundColor(cueColor)
                .scaleEffect(tenthsScale)
                .opacity(tenthsOpacity)
        }
        .font(.system(size: 96, weight: .thin).monospacedDigit())
        .minimumScaleFactor(0.35)
        .lineLimit(1)
        // White glow replicating .timerDisplay text-shadow
        .shadow(color: .white.opacity(0.30), radius: 20)
        .shadow(color: .white.opacity(0.20), radius: 40)
        // Idle breathing (timer-breathe, 4 s, only when not running)
        .scaleEffect(breatheScale)
        // No animation on colour cue — the blink rhythm is the visual effect.
        // Easing a 500 ms on/off transition just creates interference.
        .onAppear {
            // Tenths pulse — always running
            withAnimation(.easeInOut(duration: 0.125).repeatForever(autoreverses: true)) {
                tenthsScale   = 1.02
                tenthsOpacity = 0.95
            }
            // Start breathing if idle on first appear
            if engine.phase == .idle { startBreathing() }
        }
        .onChange(of: engine.phase) { _, newPhase in
            if newPhase == .idle {
                startBreathing()
            } else {
                stopBreathing()
            }
        }
    }

    private func startBreathing() {
        withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
            breatheScale = 1.01
        }
    }

    private func stopBreathing() {
        withAnimation(.easeOut(duration: 0.2)) {
            breatheScale = 1.0
        }
    }

}
