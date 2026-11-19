import XCTest
@testable import LanpixoCore

final class AdPolicyTests: XCTestCase {
    func testReservationSurvivesRestartAndRefundsExactlyOnce() throws {
        var ledger = AdCreditLedger()
        XCTAssertFalse(ledger.reserve())
        ledger.earn(); XCTAssertTrue(ledger.reserve()); XCTAssertFalse(ledger.reserve())
        let stored = try JSONEncoder().encode(ledger)
        var restored = try JSONDecoder().decode(AdCreditLedger.self, from: stored)
        restored.finish(completed: false); restored.finish(completed: false)
        XCTAssertEqual(restored.balance, 1)
        XCTAssertTrue(restored.reserve()); restored.finish(completed: true)
        XCTAssertEqual(restored.balance, 0)
    }
    func testAdFrequencyBoundariesAndClockRollback() {
        let last = Date(timeIntervalSince1970: 1000)
        XCTAssertFalse(AdFrequencyPolicy.eligible(completions: 2, lastShown: last, now: last.addingTimeInterval(200)))
        XCTAssertFalse(AdFrequencyPolicy.eligible(completions: 3, lastShown: last, now: last.addingTimeInterval(179)))
        XCTAssertFalse(AdFrequencyPolicy.eligible(completions: 3, lastShown: last, now: last.addingTimeInterval(-1)))
        XCTAssertTrue(AdFrequencyPolicy.eligible(completions: 3, lastShown: last, now: last.addingTimeInterval(180)))
    }
}
