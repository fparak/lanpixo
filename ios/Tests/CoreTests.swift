import XCTest
@testable import LanpixoCore

final class CoreTests: XCTestCase {
    func testSubnetEdges() throws {
        let subnet = try IPv4Subnet(address: "192.168.2.25", mask: "255.255.255.0")
        XCTAssertEqual(subnet.cidr, "192.168.2.0/24")
        XCTAssertEqual(subnet.hosts.count, 254)
        XCTAssertFalse(subnet.contains("192.168.2.0"))
        XCTAssertFalse(subnet.contains("192.168.2.255"))
        XCTAssertFalse(subnet.contains("192.168.3.1"))
        XCTAssertEqual(try IPv4Subnet(address: "10.1.3.254", mask: "255.255.252.0").hosts.count, 1022)
        XCTAssertEqual(try IPv4Subnet(address: "255.255.255.253", mask: "255.255.255.252").hosts, ["255.255.255.253", "255.255.255.254"])
    }
    func testRejectsUnsafeRangesAndMalformedInput() {
        for pair in [("10.0.0.1", "255.255.248.0"), ("10.0.0.1", "255.0.255.0"), ("10.0.0.0", "255.255.255.0"), ("10.0.0.1", "255.255.255.254")] {
            XCTAssertThrowsError(try IPv4Subnet(address: pair.0, mask: pair.1))
        }
        for ip in ["256.1.2.3", "1.2.3", "1..2.3", "-1.2.3.4", "1.2.3.4.5"] { XCTAssertNil(IPv4Subnet.number(ip)) }
    }
    func testCSVFormulaInjectionAndQuoting() {
        XCTAssertEqual(CSVReport.field("=1+1"), "\"'=1+1\"")
        XCTAssertEqual(CSVReport.field(" a,\"b\""), "\" a,\"\"b\"\"\"")
        XCTAssertEqual(CSVReport.field("\t@command"), "\"'\t@command\"")
    }
}
