//
//  CueLogic.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Pure functions mirroring update_blink_state from main.rs (Appendix D).
//  No side effects, no UI dependencies — fully unit-testable.
//

import Foundation

enum CueLogic {
    // From BLINKED_COUNT in main.rs
    static let blinkCount = 3

    // Decomposes a remaining-time Double (seconds) into whole-seconds and tenths.
    // Mirrors the (r, t) extraction used by update_blink_state.
    //   totalTenths = floor(remaining * 10)
    //   r           = totalTenths / 10   (whole seconds remaining, tenths ignored)
    //   t           = totalTenths % 10   (tenths digit, 0–9)
    static func decompose(remaining: Double) -> (r: Int, t: Int) {
        let totalTenths = max(0, Int(floor(remaining * 10)))
        return (r: totalTenths / 10, t: totalTenths % 10)
    }

    // Pure color-cue computation, derived from update_blink_state (Appendix D).
    //
    // Parameters:
    //   R     — configured interval in whole seconds
    //   r     — whole seconds remaining (tenths ignored)
    //   t     — tenths digit of remaining time (0–9)
    //   round — current round, 1-based
    //
    // Rules (in order, first match wins):
    //   1. R ≤ 7 → none  (too short; blink would be constant and distracting)
    //   2. Green if round > 1 AND r ∈ (R-4, R)  — solid for first 3 s of rounds ≥ 2.
    //      Deliberate deviation from source (which gated on t ≤ 4): the native port
    //      makes green solid so it appears immediately at the round boundary rather
    //      than 0.5 s later when the tenths digit first drops to 4.
    //   3. Red   if r ∈ [1, 3] AND t ≤ 4        — blink for last 3 s of every round.
    //   4. none
    static func colorCue(R: Int, r: Int, t: Int, round: Int) -> ColorCue {
        guard R > 2 * blinkCount + 1 else { return .none }

        if round > 1 && r > R - (blinkCount + 1) && r < R {
            return .green
        }

        if r > 0 && r <= blinkCount && t <= 4 {
            return .red
        }

        return .none
    }
}
