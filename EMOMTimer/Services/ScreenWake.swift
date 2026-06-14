//
//  ScreenWake.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//

import UIKit

struct ScreenWake {
    func enable() {
        UIApplication.shared.isIdleTimerDisabled = true
    }

    func disable() {
        UIApplication.shared.isIdleTimerDisabled = false
    }
}
