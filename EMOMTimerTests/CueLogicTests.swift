//
//  CueLogicTests.swift
//  EMOMTimerTests
//
//  Copyright (c) 2025 John Cairns. All rights reserved.
//  Licensed under BSD-3-Clause License
//
//  Ports the update_blink_state tests from Appendix D of IMPLEMENTATION_PROMPT.md
//  and adds coverage for CueLogic.decompose.
//
//  One deliberate deviation from the source is noted inline: green is solid
//  (no t≤4 gate), so the native port fires green immediately at the round
//  boundary rather than 0.5 s later.
//

import XCTest
// CueLogic.swift and ColorCue.swift are compiled directly into this
// test target (listed in its Sources phase), so no module import needed.

final class CueLogicDecomposeTests: XCTestCase {
    func testWholeSeconds() {
        let (r, t) = CueLogic.decompose(remaining: 59.0)
        XCTAssertEqual(r, 59)
        XCTAssertEqual(t, 0)
    }

    func testTenthsDigit() {
        let (r, t) = CueLogic.decompose(remaining: 59.4)
        XCTAssertEqual(r, 59)
        XCTAssertEqual(t, 4)
    }

    func testAlmostNextSecond() {
        let (r, t) = CueLogic.decompose(remaining: 59.999)
        XCTAssertEqual(r, 59)
        XCTAssertEqual(t, 9)
    }

    func testZero() {
        let (r, t) = CueLogic.decompose(remaining: 0.0)
        XCTAssertEqual(r, 0)
        XCTAssertEqual(t, 0)
    }

    func testNegativeClampsToZero() {
        let (r, t) = CueLogic.decompose(remaining: -1.0)
        XCTAssertEqual(r, 0)
        XCTAssertEqual(t, 0)
    }

    func testThreePointFour() {
        let (r, t) = CueLogic.decompose(remaining: 3.4)
        XCTAssertEqual(r, 3)
        XCTAssertEqual(t, 4)
    }
}

// MARK: - Red cue (ported verbatim from Appendix D)

final class CueLogicRedTests: XCTestCase {
    // test_red_blink_at_3_seconds
    func testRedAt3SecondsTenths0() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 0, round: 1), .red)
    }

    // test_red_blink_at_3_seconds_middle
    func testRedAt3SecondsTenths4() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 4, round: 1), .red)
    }

    // test_no_red_blink_at_3_seconds_late  (t=5 is past the blink window)
    func testNoRedAt3SecondsTenths5() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 5, round: 1), .none)
    }

    // test_red_blink_at_1_second
    func testRedAt1Second() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 1, t: 2, round: 1), .red)
    }

    // test_red_blink_at_2_seconds
    func testRedAt2Seconds() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 2, t: 1, round: 1), .red)
    }

    // test_no_red_blink_at_0_seconds  (r=0 fails r>0 guard)
    func testNoRedAtZeroSeconds() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 0, t: 5, round: 1), .none)
    }
}

// MARK: - Green cue (ported with native-port adaptations)

final class CueLogicGreenTests: XCTestCase {
    // test_no_green_blink_round_1
    func testNoGreenOnRound1() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 0, round: 1), .none)
    }

    // Green uses t≥5 (first half of each second, opposite phase from red).
    // At round advance remaining≈R−ε so t=9 ≥ 5 → fires immediately.

    // test_green_blink_at_59_seconds_round_2 (t=9, start of second → green ON)
    func testGreenAt59SecondsRound2_t9() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 9, round: 2), .green)
    }

    func testGreenAt59SecondsRound2_t5() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 5, round: 2), .green)
    }

    // test_green_blink_at_58_seconds_round_5
    func testGreenAt58SecondsRound5() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 58, t: 7, round: 5), .green)
    }

    // test_green_blink_at_57_seconds
    func testGreenAt57Seconds() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 57, t: 5, round: 2), .green)
    }

    // test_no_green_blink_at_60_seconds  (r < R: 60 < 60 is false)
    func testNoGreenWhenRemainingEqualsInterval() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 60, t: 9, round: 2), .none)
    }

    // test_no_green_blink_at_56_seconds  (r > R−4: 56 > 56 is false)
    func testNoGreenAt56Seconds() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 56, t: 9, round: 2), .none)
    }

    // Green blink-off: t < 5 (second half of each second) → none
    func testNoGreenAtT4_blinkOff() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 4, round: 2), .none)
    }

    func testNoGreenAt58Seconds_t0() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 58, t: 0, round: 3), .none)
    }
}

// MARK: - None / guard cases

final class CueLogicNoneTests: XCTestCase {
    // test_no_blink_at_30_seconds
    func testNoBlinkMidRound() {
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 30, t: 5, round: 3), .none)
    }

    // Short-interval guard: R ≤ 7 always returns none
    func testShortIntervalGuard() {
        for R in 1...7 {
            XCTAssertEqual(
                CueLogic.colorCue(R: R, r: 1, t: 0, round: 2), .none,
                "Expected .none for R=\(R)"
            )
        }
    }

    // Minimum interval that activates cues: R=8
    func testMinimumIntervalForCues() {
        XCTAssertEqual(CueLogic.colorCue(R: 8, r: 1, t: 0, round: 1), .red)
    }

    // §8 acceptance criteria spot-checks
    func testAcceptanceCriteria() {
        // round=1, r=59 → none
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 0, round: 1), .none)
        // round=2, r=59 → green (immediate at t=9, first half of second)
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 59, t: 9, round: 2), .green)
        // round=2, r=57, t=5 → green
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 57, t: 5, round: 2), .green)
        // round=2, r=56 → none
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 56, t: 0, round: 2), .none)
        // round=2, r=60 → none
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 60, t: 0, round: 2), .none)
        // round=1, r=3, t=0 → red
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 0, round: 1), .red)
        // r=3, t=4 → red
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 4, round: 1), .red)
        // r=3, t=5 → none
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 3, t: 5, round: 1), .none)
        // r=1, t=2 → red
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 1, t: 2, round: 1), .red)
        // r=0 → none
        XCTAssertEqual(CueLogic.colorCue(R: 60, r: 0, t: 0, round: 1), .none)
        // R≤7 → none
        XCTAssertEqual(CueLogic.colorCue(R: 7, r: 1, t: 0, round: 2), .none)
    }
}
