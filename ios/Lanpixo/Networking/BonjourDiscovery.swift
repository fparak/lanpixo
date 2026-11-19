import Foundation
import Darwin

/// Uses declared service types through Bonjour; no raw multicast entitlement is assumed.
@MainActor final class BonjourDiscovery: NSObject, NetServiceBrowserDelegate, NetServiceDelegate {
    static let types = ["_http._tcp.", "_https._tcp.", "_ssh._tcp.", "_smb._tcp.", "_ipp._tcp.", "_ipps._tcp.", "_airplay._tcp.", "_raop._tcp.", "_googlecast._tcp.", "_companion-link._tcp.", "_hap._tcp.", "_workstation._tcp."]
    private var browsers: [NetServiceBrowser] = []
    private var services: [NetService] = []
    var onDevice: ((String, String) -> Void)?
    var onDenied: (() -> Void)?
    func start() {
        stop()
        for type in Self.types {
            let browser = NetServiceBrowser()
            browser.delegate = self; browsers.append(browser)
            browser.searchForServices(ofType: type, inDomain: "local.")
        }
    }
    func stop() {
        browsers.forEach { $0.stop(); $0.delegate = nil }; browsers.removeAll()
        services.forEach { $0.stop(); $0.delegate = nil }; services.removeAll()
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        guard services.count < 512 else { return }
        services.append(service); service.delegate = self; service.resolve(withTimeout: 4)
    }
    func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String: NSNumber]) {
        if errorDict[NetService.errorCode]?.intValue == -72008 { onDenied?() }
    }
    func netServiceDidResolveAddress(_ sender: NetService) {
        for data in sender.addresses ?? [] {
            guard data.count >= MemoryLayout<sockaddr_in>.size else { continue }
            var address = sockaddr_in()
            _ = withUnsafeMutableBytes(of: &address) { data.copyBytes(to: $0) }
            guard address.sin_family == UInt8(AF_INET) else { continue }
            var raw = address.sin_addr
            var buffer = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            guard inet_ntop(AF_INET, &raw, &buffer, socklen_t(buffer.count)) != nil else { continue }
            onDevice?(String(cString: buffer), String(sender.name.prefix(120)))
        }
    }
}
