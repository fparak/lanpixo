import Foundation
import Network
import Darwin

struct WiFiSnapshot: Equatable {
    let interface: String
    let address: String
    let mask: String
    var subnet: IPv4Subnet { get throws { try IPv4Subnet(address: address, mask: mask) } }

    static func current(path: NWPath) throws -> WiFiSnapshot {
        guard path.status == .satisfied, path.usesInterfaceType(.wifi) else { throw NetworkFailure.noWiFi }
        let names = Set(path.availableInterfaces.filter { $0.type == .wifi }.map(\.name))
        var list: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&list) == 0 else { throw NetworkFailure.noWiFi }
        defer { freeifaddrs(list) }
        var entry = list
        while let pointer = entry {
            defer { entry = pointer.pointee.ifa_next }
            let item = pointer.pointee
            let name = String(cString: item.ifa_name)
            guard names.contains(name), let addr = item.ifa_addr, let mask = item.ifa_netmask,
                  addr.pointee.sa_family == UInt8(AF_INET), item.ifa_flags & UInt32(IFF_UP) != 0 else { continue }
            func literal(_ address: UnsafeMutablePointer<sockaddr>) -> String {
                var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                guard getnameinfo(address, socklen_t(address.pointee.sa_len), &buffer, socklen_t(buffer.count), nil, 0, NI_NUMERICHOST) == 0 else { return "" }
                return String(cString: buffer)
            }
            let result = WiFiSnapshot(interface: name, address: literal(addr), mask: literal(mask))
            _ = try result.subnet
            return result
        }
        throw NetworkFailure.noWiFi
    }
}

enum PortState: String { case open, closed, noResponse }

/// Each probe resumes exactly once, including timeout, task cancellation and refused connections.
final class TCPProbe: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<PortState, Never>?
    private var connection: NWConnection?
    private var timeout: DispatchWorkItem?
    private var finished = false

    private func finish(_ state: PortState) {
        lock.lock()
        guard !finished else { lock.unlock(); return }
        finished = true
        let completion = continuation; continuation = nil
        let active = connection; connection = nil
        let timer = timeout; timeout = nil
        lock.unlock()
        timer?.cancel(); active?.cancel(); completion?.resume(returning: state)
    }
    func run(ip: String, port: UInt16, timeout seconds: Double = 0.6) async -> PortState {
        await withTaskCancellationHandler(operation: {
            await withCheckedContinuation { completion in
                let parameters = NWParameters.tcp
                parameters.requiredInterfaceType = .wifi
                parameters.includePeerToPeer = false
                let active = NWConnection(host: NWEndpoint.Host(ip), port: NWEndpoint.Port(rawValue: port)!, using: parameters)
                let timer = DispatchWorkItem { [weak self] in self?.finish(.noResponse) }
                lock.lock()
                if finished { lock.unlock(); completion.resume(returning: .noResponse); return }
                continuation = completion; connection = active; timeout = timer
                lock.unlock()
                active.stateUpdateHandler = { [weak self] state in
                    switch state {
                    case .ready: self?.finish(.open)
                    case .failed(let error):
                        if case .posix(let code) = error, code == .ECONNREFUSED { self?.finish(.closed) }
                        else { self?.finish(.noResponse) }
                    default: break
                    }
                }
                active.start(queue: .global(qos: .utility))
                DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + seconds, execute: timer)
            }
        }, onCancel: { self.finish(.noResponse) })
    }
}
