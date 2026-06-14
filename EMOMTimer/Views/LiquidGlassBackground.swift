//
//  LiquidGlassBackground.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Native reproduction of the web app's liquid-glass aesthetic (Appendix A).
//  Palette, cloud geometry, and animation durations match the CSS source.
//
//  Animation strategy: all motion is derived from wall-clock time via sin/cos
//  inside a TimelineView. There are no @State booleans and no withAnimation
//  calls, which means there are no reversal points, no restart artifacts, and
//  no interaction with SwiftUI's view-update cycle — the animation is
//  mathematically guaranteed to be smooth and continuous at all times.
//

import SwiftUI

// MARK: - Hex colour convenience (used across Views)

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Background

struct LiquidGlassBackground: View {
    private let gradientColors: [Color] = [
        Color(hex: 0x667eea),
        Color(hex: 0x764ba2),
        Color(hex: 0xf093fb),
    ]

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                let t = context.date.timeIntervalSinceReferenceDate
                ZStack {
                    gradientLayer(t: t)
                    cloudLayer1(t: t, size: geo.size)
                    cloudLayer2(t: t, size: geo.size)
                }
            }
        }
    }

    // CSS gradient-shift: 15 s cycle.
    // The angle swings ±20° around 135° (range 115°–155°) so it is always
    // clearly diagonal and never approaches vertical or horizontal — the
    // region that caused the earlier colour-inversion artifact.
    //
    // CSS angle convention (clockwise from "to top"):
    //   direction vector in SwiftUI y-down space = (sin θ, −cos θ)
    // startPoint / endPoint are placed 0.75 units from centre; values
    // outside [0,1] are legal for UnitPoint and let the gradient reach
    // beyond the view edges exactly like CSS background-size: 400%.
    @ViewBuilder
    private func gradientLayer(t: Double) -> some View {
        let phase = t / 15.0 * .pi * 2
        let θ     = (135.0 + 20.0 * sin(phase)) * .pi / 180.0
        let dx    = CGFloat(sin(θ))
        let dy    = CGFloat(-cos(θ))
        let s: CGFloat = 0.75
        LinearGradient(
            colors: gradientColors,
            startPoint: UnitPoint(x: 0.5 - dx * s, y: 0.5 - dy * s),
            endPoint:   UnitPoint(x: 0.5 + dx * s, y: 0.5 + dy * s)
        )
        // Mild hue shift (±15°, 11 s period) layered on top of the angle
        // animation so the colours gently drift without dominating or flipping.
        // Different period from the angle (15 s) creates organic combined motion.
        .hueRotation(.degrees(15 * sin(t / 11.0 * .pi * 2)))
    }

    // CSS body::before — clouds-drift-1 30 s, blur 22 px
    @ViewBuilder
    private func cloudLayer1(t: Double, size: CGSize) -> some View {
        let p  = t / 30.0 * .pi * 2
        let dx = CGFloat(sin(p))        * size.width  * 0.02
        let dy = CGFloat(cos(p * 0.71)) * size.height * 0.01

        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.35))
                .frame(width: size.width * 1.10, height: size.height * 0.20)
                .offset(x: size.width * -0.25 + dx,        y: size.height * 0.30 + dy)
            Ellipse()
                .fill(Color.white.opacity(0.28))
                .frame(width: size.width * 0.90, height: size.height * 0.17)
                .offset(x: size.width *  0.20 + dx * 0.8,  y: size.height * 0.20 - dy)
            Ellipse()
                .fill(Color.white.opacity(0.38))
                .frame(width: size.width * 1.20, height: size.height * 0.22)
                .offset(x: size.width * -0.10 + dx * 1.2,  y: size.height * 0.70 + dy * 0.6)
        }
        .blur(radius: 22)
        .mask(
            RadialGradient(
                colors: [.black, .clear],
                center: .center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.65
            )
        )
    }

    // CSS body::after — clouds-drift-2 40 s, blur 26 px, reversed (negative phase)
    @ViewBuilder
    private func cloudLayer2(t: Double, size: CGSize) -> some View {
        let p  = -t / 40.0 * .pi * 2    // negative = reverse direction per CSS
        let dx = CGFloat(sin(p))         * size.width  * 0.015
        let dy = CGFloat(cos(p * 0.50))  * size.height * 0.012

        ZStack {
            Ellipse()
                .fill(Color.white.opacity(0.32))
                .frame(width: size.width * 1.10, height: size.height * 0.19)
                .offset(x: size.width *  0.15 + dx,        y: size.height * 0.40 + dy)
            Ellipse()
                .fill(Color.white.opacity(0.36))
                .frame(width: size.width * 1.00, height: size.height * 0.21)
                .offset(x: size.width * -0.20 - dx,        y: size.height * 0.80 - dy)
            Ellipse()
                .fill(Color.white.opacity(0.30))
                .frame(width: size.width * 1.30, height: size.height * 0.23)
                .offset(x: size.width *  0.35 + dx * 0.7,  y: size.height * 0.65 + dy * 0.8)
        }
        .blur(radius: 26)
        .mask(
            RadialGradient(
                colors: [.black, .clear],
                center: .center,
                startRadius: 0,
                endRadius: max(size.width, size.height) * 0.65
            )
        )
    }
}

// MARK: - Glass card

/// Frosted glass card replicating the #background CSS element.
///   fill:   rgba(255,255,255,0.12) + backdrop-filter blur(20px) saturate(160%)
///   border: 1px rgba(255,255,255,0.25)
///   shadow: 0 8px 32px rgba(31,38,135,0.37)
struct GlassCard<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                    )
                    .shadow(
                        color: Color(hex: 0x1f2687).opacity(0.37),
                        radius: 16, x: 0, y: 8
                    )
            )
    }
}
