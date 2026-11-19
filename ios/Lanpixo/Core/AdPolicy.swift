import Foundation

/// One encoded transaction prevents a crash between balance and reservation writes.
struct AdCreditLedger: Codable, Equatable {
    var balance = 0
    var reserved = false
    mutating func earn() { balance = min(1000, balance + 1) }
    mutating func reserve() -> Bool {
        guard balance > 0, !reserved else { return false }
        balance -= 1; reserved = true; return true
    }
    mutating func finish(completed: Bool) {
        guard reserved else { return }
        if !completed { balance = min(1000, balance + 1) }
        reserved = false
    }
}

enum AdFrequencyPolicy {
    static func eligible(completions: Int, lastShown: Date, now: Date) -> Bool {
        completions >= 3 && now.timeIntervalSince(lastShown) >= 180
    }
}
