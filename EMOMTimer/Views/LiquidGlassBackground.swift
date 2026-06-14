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
    @State private var gradientShift = false
    @State private var cloud1Drift   = false
    @State private var cloud2Drift   = false

    // CSS source: #667eea → #764ba2 → #f093fb, 135° gradient, 15 s cycle
    private let gradientColors: [Color] = [
        Color(hex: 0x667eea),
        Color(hex: 0x764ba2),
        Color(hex: 0xf093fb),
    ]

    var body: some View {
        ZStack {
            // Animated gradient (simulates CSS background-size:400% animation)
            LinearGradient(
                colors: gradientColors,
                startPoint: gradientShift ? .topLeading    : .bottomTrailing,
                endPoint:   gradientShift ? .bottomTrailing : .topLeading
            )

            // Cloud layer 1 (body::before) — 30 s drift
            cloudLayer1

            // Cloud layer 2 (body::after) — 40 s drift, reversed
            cloudLayer2
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 7.5).repeatForever(autoreverses: true)) {
                gradientShift = true
            }
            withAnimation(.easeInOut(duration: 15).repeatForever(autoreverses: true)) {
                cloud1Drift = true
            }
            withAnimation(.easeInOut(duration: 20).repeatForever(autoreverses: true)) {
                cloud2Drift = true
            }
        }
    }

    // CSS: three radial gradients at 20%/80%/40% horizontal, blurred 22 px
    private var cloudLayer1: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: geo.size.width * 1.1, height: 160)
                    .offset(x: geo.size.width * -0.3,
                            y: geo.size.height * 0.3 + (cloud1Drift ? 8 : -8))
                Ellipse()
                    .fill(Color.white.opacity(0.28))
                    .frame(width: geo.size.width * 0.9, height: 140)
                    .offset(x: geo.size.width * 0.25,
                            y: geo.size.height * 0.2 + (cloud1Drift ? -6 : 6))
                Ellipse()
                    .fill(Color.white.opacity(0.38))
                    .frame(width: geo.size.width * 1.2, height: 180)
                    .offset(x: geo.size.width * -0.1,
                            y: geo.size.height * 0.7 + (cloud1Drift ? 10 : -10))
            }
            .blur(radius: 22)
            .mask(
                RadialGradient(
                    gradient: Gradient(colors: [.black, .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
            )
        }
    }

    // CSS: three radial gradients at 60%/30%/90% horizontal, blurred 26 px, reversed
    private var cloudLayer2: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(Color.white.opacity(0.32))
                    .frame(width: geo.size.width * 1.1, height: 150)
                    .offset(x: geo.size.width * 0.15,
                            y: geo.size.height * 0.4 + (cloud2Drift ? -12 : 12))
                Ellipse()
                    .fill(Color.white.opacity(0.36))
                    .frame(width: geo.size.width,     height: 170)
                    .offset(x: geo.size.width * -0.2,
                            y: geo.size.height * 0.8 + (cloud2Drift ? 6 : -6))
                Ellipse()
                    .fill(Color.white.opacity(0.30))
                    .frame(width: geo.size.width * 1.3, height: 190)
                    .offset(x: geo.size.width * 0.4,
                            y: geo.size.height * 0.7 + (cloud2Drift ? -8 : 8))
            }
            .blur(radius: 26)
            .mask(
                RadialGradient(
                    gradient: Gradient(colors: [.black, .clear]),
                    center: .center,
                    startRadius: 0,
                    endRadius: max(geo.size.width, geo.size.height) * 0.7
                )
            )
        }
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
