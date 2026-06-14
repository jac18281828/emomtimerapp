//
//  AudioCuePlayer.swift
//  EMOMTimer
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Synthesizes short beeps via AVAudioEngine — no bundled assets needed.
//  Category .playback + .mixWithOthers so beeps play alongside the user's
//  music and are audible even with the silent switch engaged (gym behaviour).
//

import AVFoundation

final class AudioCuePlayer {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private static let sampleRate: Double = 44100
    private static let format = AVAudioFormat(
        standardFormatWithSampleRate: sampleRate, channels: 1)!

    // Pre-generated buffers — built lazily once on first activate.
    private var countdownBuffer: AVAudioPCMBuffer?
    private var boundaryBuffer:  AVAudioPCMBuffer?
    private var finishBuffer:    AVAudioPCMBuffer?

    private var ready = false

    func activate() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, options: .mixWithOthers)
            try session.setActive(true)
        } catch {}

        guard !ready else {
            if !engine.isRunning { try? engine.start() }
            if !player.isPlaying { player.play() }
            return
        }

        engine.attach(player)
        engine.connect(player, to: engine.mainMixerNode, format: Self.format)
        do {
            try engine.start()
        } catch {
            return
        }
        player.play()

        countdownBuffer = makeTone(freq: 880,  duration: 0.08)  // A5 — last-3-s beep
        boundaryBuffer  = makeTone(freq: 1047, duration: 0.12)  // C6 — round boundary "go"
        finishBuffer    = makeTone(freq: 1319, duration: 0.25)  // E6 — session finish

        ready = true
    }

    func deactivate() {
        player.stop()
        engine.stop()
        try? AVAudioSession.sharedInstance().setActive(
            false, options: .notifyOthersOnDeactivation)
        ready = false
    }

    func playCountdownBeep() { schedule(countdownBuffer) }
    func playBoundaryBeep()  { schedule(boundaryBuffer) }
    func playFinishTone()    { schedule(finishBuffer) }

    // MARK: - Private

    private func schedule(_ buffer: AVAudioPCMBuffer?) {
        guard ready, let buffer else { return }
        player.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
    }

    private func makeTone(freq: Double, duration: Double) -> AVAudioPCMBuffer? {
        let sR = Self.sampleRate
        let frameCount = AVAudioFrameCount(sR * duration)
        guard let buf = AVAudioPCMBuffer(pcmFormat: Self.format,
                                         frameCapacity: frameCount),
              let ch = buf.floatChannelData?[0] else { return nil }
        buf.frameLength = frameCount

        for i in 0..<Int(frameCount) {
            let t  = Double(i) / sR
            let s  = Float(sin(2.0 * Double.pi * freq * t))
            // 5 ms attack, 20 ms release — keeps the beep crisp, not clicky
            let att = Float(min(1.0, t / 0.005))
            let rel = Float(min(1.0, (duration - t) / 0.020))
            ch[i] = s * min(att, rel) * 0.5
        }
        return buf
    }
}
