import Foundation

struct IPv4Subnet: Equatable {
    let address: UInt32
    let prefix: Int
    let network: UInt32
    let broadcast: UInt32

    init(address: String, mask: String) throws {
        guard let ip = Self.number(address), let bits = Self.number(mask) else { throw NetworkFailure.invalidSubnet }
        let prefix = bits.nonzeroBitCount
        let expected = prefix == 0 ? UInt32(0) : UInt32.max << (32 - prefix)
        guard bits == expected, (22...30).contains(prefix) else { throw NetworkFailure.invalidSubnet }
        self.address = ip; self.prefix = prefix
        network = ip & bits; broadcast = network | ~bits
        guard ip > network && ip < broadcast else { throw NetworkFailure.invalidSubnet }
    }
    var hosts: [String] { ((network + 1)..<broadcast).map(Self.string) }
    var cidr: String { "\(Self.string(network))/\(prefix)" }
    func contains(_ ip: String) -> Bool {
        guard let value = Self.number(ip) else { return false }
        return value > network && value < broadcast
    }
    static func number(_ text: String) -> UInt32? {
        let pieces = text.split(separator: ".", omittingEmptySubsequences: false)
        guard pieces.count == 4 else { return nil }
        var result: UInt32 = 0
        for piece in pieces {
            guard !piece.isEmpty, piece.utf8.allSatisfy({ (48...57).contains($0) }), let n = UInt32(piece), n <= 255 else { return nil }
            result = (result << 8) | n
        }
        return result
    }
    static func string(_ number: UInt32) -> String {
        [24, 16, 8, 0].map { String((number >> $0) & 255) }.joined(separator: ".")
    }
}

enum NetworkFailure: Error {
    case noWiFi, invalidSubnet, changed, http, bodySize, permission, cancelled
}
