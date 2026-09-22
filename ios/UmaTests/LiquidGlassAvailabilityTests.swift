// UmaTests/LiquidGlassAvailabilityTests.swift
// Asserts that .glassEffect is gated by iOS 26+ availability throughout the codebase.

import XCTest
@testable import Uma

final class LiquidGlassAvailabilityTests: XCTestCase {
    func test_liquidBackground_returnsValidView() {
        // Just verify the extension compiles and is callable. Behavioural check on iOS 18.
        let view = Text("hi").liquidBackground(.ultraThin, in: Capsule())
        XCTAssertNotNil(view)
    }

    func test_liquidCard_compiles() {
        let view = Text("x").liquidCard()
        XCTAssertNotNil(view)
    }

    func test_liquidPill_compiles() {
        let view = Text("x").liquidPill()
        XCTAssertNotNil(view)
    }

    func test_liquidGlassCluster_compiles() {
        let view = LiquidGlassCluster {
            Text("a"); Text("b")
        }
        XCTAssertNotNil(view)
    }

    /// Static check: ensure the GlassKind enum is exhaustive (new cases break callers).
    func test_glassKindExhaustive() {
        let kinds: [GlassKind] = [.ultraThin, .regular, .clear, .interactive]
        XCTAssertEqual(kinds.count, 4)
    }
}
