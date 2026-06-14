//
//  TimerEngine.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Wall-clock–based EMOM timer engine.
//
//  Timing model: instead of accumulating ticks (like the Rust/WASM source's
//  CountdownTimer which fought browser throttling), all time is derived from
//  Date() — the system clock is the single source of truth.
//
//    elapsed   = Date().timeIntervalSince(roundStartDate)
//    remaining = intervalDuration - elapsed
//
//  Round rollover: advance roundStartDate by exactly one intervalDuration
//  (phase-lock) so boundaries stay phase-aligned to the original start,
//  preventing cumulative drift across many rounds.
//

import Foundation
import Observation

@Observable
final class TimerEngine {

    // MARK: - Config (persisted across launches)

    private(set) var intervalDuration: Double  // seconds; default 60
    private(set) var rounds: Int               // default 5

    // MARK: - Runtime (observable — drive UI updates)

    private(set) var phase: TimerPhase = .idle
    private(set) var currentRound: Int = 1
    /// Updated at ~30 Hz when running; frozen when paused/idle.
    private(set) var displayRemaining: Double

    // MARK: - Private wall-clock state

    private var roundStartDate: Date = .now
    private var pausedRemaining: Double

    // MARK: - Services

    private let audio      = AudioCuePlayer()
    private let haptics    = Haptics()
    private let screenWake = ScreenWake()

    // MARK: - Effect-firing guards (prevent double-firing)

    private var lastBeepR: Int = -1            // last r value for which a countdown beep fired
    private var firedBoundaryForRound: Int = 0 // round number for which boundary beep+haptic fired
    private var firedFinish = false
    // Mirrors clear_blink_state() from the Rust source: set to true by any
    // interval/round adjustment, cleared on the next processFrame tick.
    // Prevents the colour cue from persisting across a button press even if
    // the newly-computed values happen to still land in a blink zone.
    private var blinkSuppressed = false

    // MARK: - Frame timer

    private var frameTimer: Timer?

    // MARK: - Persistence keys

    private static let intervalKey = "emom.intervalDuration"
    private static let roundsKey   = "emom.rounds"

    // MARK: - Init

    init() {
        // Resolve persisted values into locals first so we can initialize all
        // stored properties before any self-access (Swift init rules).
        let stored = UserDefaults.standard.double(forKey: Self.intervalKey)
        let interval = stored > 0 ? stored : 60.0

        let storedRounds = UserDefaults.standard.integer(forKey: Self.roundsKey)

        intervalDuration = interval
        rounds           = storedRounds > 0 ? storedRounds : 5
        pausedRemaining  = interval
        displayRemaining = interval
    }

    // MARK: - Public intents

    func start() {
        switch phase {
        case .running:
            return

        case .paused:
            // Resume: reanchor the wall-clock so remaining = pausedRemaining
            roundStartDate = Date().addingTimeInterval(-(intervalDuration - pausedRemaining))
            phase = .running
            screenWake.enable()
            startFrameTimer()

        case .idle:
            // Fresh start (or restart after last round finished)
            if currentRound >= rounds { currentRound = 1 }
            roundStartDate = Date()
            resetEffectTracking()
            phase = .running
            audio.activate()
            haptics.prepare()
            screenWake.enable()
            startFrameTimer()
        }
    }

    func pause() {
        guard phase == .running else { return }
        pausedRemaining = displayRemaining
        phase = .paused
        stopFrameTimer()
        screenWake.disable()
    }

    func reset() {
        stopFrameTimer()
        phase = .idle
        currentRound = 1
        intervalDuration = 60.0
        rounds = 5
        pausedRemaining  = 60.0
        displayRemaining = 60.0
        resetEffectTracking()
        blinkSuppressed = false
        screenWake.disable()
        audio.deactivate()
        UserDefaults.standard.set(intervalDuration, forKey: Self.intervalKey)
        UserDefaults.standard.set(rounds,           forKey: Self.roundsKey)
    }

    /// ±1 or ±15 second adjustment to the interval, mirroring adjust_time_by_seconds.
    ///
    /// Both the config interval and the in-progress remaining shift by delta,
    /// with remaining clamped to [0, newIntervalDuration].
    ///
    /// Wall-clock translation: remaining is not stored — it is derived from
    /// roundStartDate. To shift remaining by delta, move roundStartDate back
    /// by delta (adding time to remaining) or forward (subtracting).
    func adjustInterval(seconds delta: Int) {
        let newInterval  = max(0, intervalDuration + Double(delta))
        let currentRemaining: Double

        switch phase {
        case .running:
            currentRemaining = max(0, displayRemaining)
        case .paused:
            currentRemaining = pausedRemaining
        case .idle:
            // Idle: display == interval; both update together.
            intervalDuration = newInterval
            pausedRemaining  = newInterval
            displayRemaining = newInterval
            UserDefaults.standard.set(intervalDuration, forKey: Self.intervalKey)
            return
        }

        let newRemaining = min(max(currentRemaining + Double(delta), 0), newInterval)
        intervalDuration = newInterval

        switch phase {
        case .running:
            // Shift the wall-clock anchor so that the derived remaining equals newRemaining.
            roundStartDate = Date().addingTimeInterval(-(newInterval - newRemaining))
            displayRemaining = newRemaining
        case .paused:
            pausedRemaining  = newRemaining
            displayRemaining = newRemaining
        case .idle:
            break  // handled above
        }

        UserDefaults.standard.set(intervalDuration, forKey: Self.intervalKey)
        blinkSuppressed = true  // clear_blink_state: visual reset after any adjustment
    }

    /// ±1 round; decrement clamps at 1 and clamps currentRound down if needed.
    func adjustRounds(_ delta: Int) {
        rounds = max(1, rounds + delta)
        if currentRound > rounds { currentRound = rounds }
        UserDefaults.standard.set(rounds, forKey: Self.roundsKey)
        blinkSuppressed = true  // clear_blink_state
    }

    /// Called when the app returns to foreground — restarts the frame timer
    /// and re-establishes the audio session.  The engine self-corrects because
    /// all time is derived from the unchanged roundStartDate.
    func handleForeground() {
        guard phase == .running else { return }
        audio.activate()
        startFrameTimer()
    }

    // MARK: - Computed display helpers

    var startLabel: String { phase == .paused ? "Start ↻" : "Start ▶" }

    var isRunning: Bool { phase == .running }

    var displayString: String {
        let (r, t) = CueLogic.decompose(remaining: displayRemaining)
        let m = r / 60
        let s = r % 60
        return "\(m):\(String(format: "%02d", s)).\(t)"
    }

    var intervalString: String {
        let s = Int(max(0, intervalDuration))
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }

    var colorCue: ColorCue {
        guard !blinkSuppressed else { return .none }
        let (r, t) = CueLogic.decompose(remaining: displayRemaining)
        let R = Int(intervalDuration.rounded())
        return CueLogic.colorCue(R: R, r: r, t: t, round: currentRound)
    }

    // MARK: - Frame timer

    private func startFrameTimer() {
        frameTimer?.invalidate()
        // Use Timer(timeInterval:repeats:block:) + manual add to avoid the
        // scheduledTimer double-add issue (scheduledTimer adds to .default;
        // we add to .common which also covers .default and .tracking).
        let t = Timer(timeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.processFrame()
        }
        RunLoop.main.add(t, forMode: .common)
        frameTimer = t
    }

    private func stopFrameTimer() {
        frameTimer?.invalidate()
        frameTimer = nil
    }

    private func processFrame() {
        guard phase == .running else { return }
        blinkSuppressed = false   // clear_blink_state: one tick after an adjustment

        let now = Date()
        var r   = intervalDuration - now.timeIntervalSince(roundStartDate)

        // Advance through any round boundaries that have passed.
        // Phase-lock: move anchor by exactly one intervalDuration per boundary
        // so that boundaries stay aligned to the original start time.
        var boundariesCrossed = 0
        while r <= 0 {
            guard currentRound < rounds else {
                finishSession()
                return
            }
            roundStartDate = roundStartDate.addingTimeInterval(intervalDuration)
            currentRound  += 1
            r              = intervalDuration - now.timeIntervalSince(roundStartDate)
            boundariesCrossed += 1
        }

        displayRemaining = r

        // Boundary beep + haptic — only for real-time crossings (not catch-up).
        if boundariesCrossed == 1 && firedBoundaryForRound < currentRound {
            audio.playBoundaryBeep()
            haptics.fireBoundary()
            firedBoundaryForRound = currentRound
            lastBeepR = -1  // reset countdown tracking for new round
        } else if boundariesCrossed > 1 {
            // Caught up across multiple rounds while backgrounded — skip audio.
            firedBoundaryForRound = currentRound
            lastBeepR = -1
        }

        // Last-3-second countdown beeps — once per whole second, gated on R > 7.
        // Also gated on tVal <= 4 (same half-second window as the red cue) so the
        // beep fires in sync with the colour change, not 0.5 s before it.
        let R    = Int(intervalDuration.rounded())
        let (rVal, tVal) = CueLogic.decompose(remaining: r)
        if R > 7 && rVal > 0 && rVal <= CueLogic.blinkCount && tVal <= 4 && rVal != lastBeepR {
            audio.playCountdownBeep()
            haptics.fireTick()
            lastBeepR = rVal
        } else if rVal > CueLogic.blinkCount {
            lastBeepR = -1
        }
    }

    private func finishSession() {
        phase            = .idle
        displayRemaining = intervalDuration
        // currentRound stays at rounds — shows N/N until Start is pressed
        stopFrameTimer()
        screenWake.disable()
        if !firedFinish {
            audio.playFinishTone()
            firedFinish = true
        }
        // Deactivate audio after the finish tone has time to play.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.audio.deactivate()
        }
    }

    private func resetEffectTracking() {
        lastBeepR             = -1
        firedBoundaryForRound = 0
        firedFinish           = false
    }
}
