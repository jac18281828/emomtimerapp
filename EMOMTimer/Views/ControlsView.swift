//
//  ControlsView.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Nine glass buttons in source order (Appendix D view()):
//    Start ▶/↻, Pause, -Rnd, +Rnd, -15, +15, -1, +1, Reset
//
//  Layout adapts to portrait (two rows) and landscape (single row).
//  Button style replicates #buttonDisplay button CSS (Appendix A).
//

import SwiftUI

// MARK: - Button style

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .regular))
            // CSS color: #283f8a
            .foregroundColor(Color(hex: 0x283f8a))
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.55, green: 0.78, blue: 1.00).opacity(0.28),
                                Color(red: 0.35, green: 0.49, blue: 0.92).opacity(0.28),
                                Color(red: 0.27, green: 0.18, blue: 0.63).opacity(0.30),
                            ],
                            startPoint: .topLeading,
                            endPoint:   .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(
                                Color(red: 0.51, green: 0.69, blue: 1.00).opacity(0.35),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: Color(red: 0.14, green: 0.21, blue: 0.55).opacity(0.25),
                        radius: 8, x: 0, y: 4
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}

// MARK: - Controls

struct ControlsView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        if verticalSizeClass == .compact {
            // Landscape: single row of 9 buttons
            HStack(spacing: 4) { allButtons }
        } else {
            // Portrait: two rows
            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    startButton
                    pauseButton
                    rndButton(-1)
                    rndButton(+1)
                }
                HStack(spacing: 4) {
                    secButton(-15)
                    secButton(+15)
                    secButton(-1)
                    secButton(+1)
                    resetButton
                }
            }
        }
    }

    @ViewBuilder
    private var allButtons: some View {
        startButton
        pauseButton
        rndButton(-1)
        rndButton(+1)
        secButton(-15)
        secButton(+15)
        secButton(-1)
        secButton(+1)
        resetButton
    }

    private var startButton: some View {
        Button(engine.startLabel) { engine.start() }
            .buttonStyle(GlassButtonStyle())
    }

    private var pauseButton: some View {
        Button("Pause") { engine.pause() }
            .buttonStyle(GlassButtonStyle())
    }

    private func rndButton(_ delta: Int) -> some View {
        Button(delta > 0 ? "+Rnd" : "-Rnd") {
            engine.adjustRounds(delta)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private func secButton(_ delta: Int) -> some View {
        let label = delta > 0 ? "+\(delta)" : "\(delta)"
        return Button(label) {
            engine.adjustInterval(seconds: delta)
        }
        .buttonStyle(GlassButtonStyle())
    }

    private var resetButton: some View {
        Button("Reset") { engine.reset() }
            .buttonStyle(GlassButtonStyle())
    }
}
