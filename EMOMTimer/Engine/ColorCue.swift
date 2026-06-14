//
//  ColorCue.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//

import SwiftUI

enum ColorCue: Equatable {
    case none, green, red

    var timerColor: Color {
        switch self {
        case .none:  .black
        case .green: .green
        case .red:   .red
        }
    }
}
