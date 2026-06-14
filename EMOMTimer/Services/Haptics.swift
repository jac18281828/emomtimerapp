//
//  Haptics.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//

import UIKit

struct Haptics {
    private let boundary = UIImpactFeedbackGenerator(style: .medium)
    private let tick     = UIImpactFeedbackGenerator(style: .light)

    func prepare() {
        boundary.prepare()
        tick.prepare()
    }

    // Fired at each round boundary (0:00 → next round start).
    func fireBoundary() {
        boundary.impactOccurred()
    }

    // Fired on each last-3-second countdown tick (r = 3, 2, 1).
    func fireTick() {
        tick.impactOccurred()
    }
}
