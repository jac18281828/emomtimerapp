//
//  ContentView.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Single screen: full-bleed liquid-glass background with a centred glass
//  card containing the EMOM title, rounds row, timer display, and controls.
//  Layout adapts between portrait (vertical stack) and landscape (compact).
//

import SwiftUI

struct ContentView: View {
    @Environment(TimerEngine.self) private var engine
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    var body: some View {
        // Outer VStack fills the safe-area-inset content area.
        // The background extends behind safe areas via .ignoresSafeArea().
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            GlassCard {
                VStack(alignment: .leading, spacing: 0) {
                    // "EMOM" title — left-aligned portrait, centred landscape
                    Text("EMOM")
                        .font(.system(size: titleFontSize, weight: .semibold))
                        .frame(maxWidth: .infinity,
                               alignment: verticalSizeClass == .compact ? .center : .leading)
                        .padding(.bottom, verticalSizeClass == .compact ? 6 : 10)

                    RoundsView()
                        .padding(.bottom, verticalSizeClass == .compact ? 6 : 14)

                    TimerDisplayView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, verticalSizeClass == .compact ? 2 : 6)

                    ControlsView()
                        .frame(maxWidth: .infinity)   // fills card width so VStack(.center) centres rows
                        .padding(.top, verticalSizeClass == .compact ? 4 : 8)
                }
                .padding(cardPadding)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 8)
        // LiquidGlassBackground is used here as a full-bleed background;
        // .ignoresSafeArea() on the background lets it extend under the
        // status bar and home indicator while the content stack stays inset.
        .background {
            LiquidGlassBackground()
                .ignoresSafeArea()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                engine.handleForeground()
            }
        }
    }

    private var titleFontSize: CGFloat {
        verticalSizeClass == .compact ? 18 : 26
    }

    private var cardPadding: CGFloat {
        verticalSizeClass == .compact ? 10 : 20
    }
}
