import Foundation

struct Device: Identifiable, Codable {
    var id: String { ip }
    let ip: String
    var name: String
    var evidence: String
    var known = false
    var firstSeen = Date()
    var lastSeen = Date()
    var isSelf = false
}

struct ScanRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let subnet: String
    let count: Int
    let complete: Bool
}

struct SpeedResult: Identifiable, Codable {
    var id = UUID()
    var date = Date()
    let download: Double
    let upload: Double
    let latency: Double
    let bytes: Int
}

enum CSVReport {
    static func field(_ text: String) -> String {
        // Defuse spreadsheet formulas as well as escaping commas, quotes and newlines.
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let safe = ["=", "+", "-", "@"].contains(where: { trimmed.hasPrefix($0) }) ? "'" + text : text
        return "\"" + safe.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    static func render(_ devices: [Device]) -> String {
        (["IP,Name,Known,Evidence"] + devices.map {
            [$0.ip, $0.name, $0.known ? "yes" : "no", $0.evidence].map(field).joined(separator: ",")
        }).joined(separator: "\r\n")
    }
}
