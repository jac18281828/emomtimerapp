//
//  RoundsView.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Rounds row: "current/total" on the left, configured interval M:SS on the
//  right, with a hairline bottom divider — mirroring .roundsDisplay in CSS.
//

import SwiftUI

struct RoundsView: View {
    @Environment(TimerEngine.self) private var engine

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("\(engine.currentRound)/\(engine.rounds)")
                Spacer()
                Text(engine.intervalString)
            }
            .font(.system(size: 24).monospacedDigit())
            .padding(.bottom, 12)

            // Hairline divider: rgba(255,255,255,0.2)
            Rectangle()
                .fill(Color.white.opacity(0.2))
                .frame(height: 1)
        }
    }
}
