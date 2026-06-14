//
//  EMOMApp.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//

import SwiftUI

@main
struct EMOMApp: App {
    @State private var engine = TimerEngine()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(engine)
        }
    }
}
