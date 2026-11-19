import SwiftUI
import Network

@MainActor final class AppModel: ObservableObject {
    @Published var devices: [Device] = []
    @Published var history: [ScanRecord] = []
    @Published var speeds: [SpeedResult] = []
    @Published var busy = false
    @Published var progress = 0.0
    @Published var status = "ready"
    @Published var subnet = "—"
    @Published var stale = false
    @Published var portResults: [UInt16: PortState] = [:]
    @Published var language = UserDefaults.standard.string(forKey: "language") ?? "system" {
        didSet { UserDefaults.standard.set(language, forKey: "language") }
    }
    @Published var theme = UserDefaults.standard.string(forKey: "theme") ?? "system" {
        didSet { UserDefaults.standard.set(theme, forKey: "theme") }
    }
    private let monitor = NWPathMonitor(requiredInterfaceType: .wifi)
    private let discovery = BonjourDiscovery()
    private var operation: Task<Void, Never>?
    private var snapshot: WiFiSnapshot?
    private var connectedSnapshot: WiFiSnapshot?
    private var runID = UUID()
    private let defaults = UserDefaults.standard
    var turkish: Bool { language == "tr" || (language == "system" && Locale.current.language.languageCode?.identifier == "tr") }
    func text(_ en: String, _ tr: String) -> String { turkish ? tr : en }

    init() {
        devices = restore("devices", fallback: [])
        history = restore("history", fallback: [])
        speeds = restore("speeds", fallback: [])
        stale = !devices.isEmpty
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                guard let self else { return }
                let current = try? WiFiSnapshot.current(path: path)
                if self.connectedSnapshot != current, !self.devices.isEmpty { self.stale = true }
                self.connectedSnapshot = current
                if self.busy, let expected = self.snapshot, current != expected { self.stop(reason: "changed") }
            }
        }
        monitor.start(queue: DispatchQueue(label: "com.netora.scanner.wifi"))
    }
    private func restore<T: Decodable>(_ key: String, fallback: T) -> T {
        guard let data = defaults.data(forKey: key), let value = try? JSONDecoder().decode(T.self, from: data) else { return fallback }
        return value
    }
    private func save<T: Encodable>(_ value: T, key: String) {
        if let data = try? JSONEncoder().encode(value) { defaults.set(data, forKey: key) }
    }
    func persistDevices() { save(devices, key: "devices") }
    func recognize(_ ip: String, name: String) {
        guard !stale, !busy, let index = devices.firstIndex(where: { $0.ip == ip }) else { return }
        devices[index].known = true
        devices[index].name = String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(120))
        persistDevices()
    }
    private func upsert(_ device: Device) {
        if let i = devices.firstIndex(where: { $0.ip == device.ip }) {
            if !device.name.isEmpty { devices[i].name = device.name }
            devices[i].lastSeen = Date()
            if !devices[i].evidence.contains(device.evidence) { devices[i].evidence += "; " + device.evidence }
        } else { devices.append(device) }
        devices.sort { (IPv4Subnet.number($0.ip) ?? 0) < (IPv4Subnet.number($1.ip) ?? 0) }
    }
    func scan() {
        guard !busy else { return }
        do {
            let current = try WiFiSnapshot.current(path: monitor.currentPath)
            let range = try current.subnet
            snapshot = current; connectedSnapshot = current; subnet = range.cidr
            busy = true; progress = 0; stale = false; status = "scanning"
            devices = [Device(ip: current.address, name: text("This iPhone / iPad", "Bu iPhone / iPad"), evidence: "local", isSelf: true)]
            let id = UUID(); runID = id
            discovery.onDevice = { [weak self] ip, name in
                guard let self, self.runID == id, self.busy, range.contains(ip) else { return }
                self.upsert(Device(ip: ip, name: name, evidence: "Bonjour"))
            }
            discovery.onDenied = { [weak self] in self?.stop(reason: "permission") }
            discovery.start()
            operation = Task { [weak self] in
                guard let self else { return }
                let start = ContinuousClock.now
                let deadline = start.advanced(by: .seconds(120))
                let hosts = range.hosts.filter { $0 != current.address }
                var completed = 0
                for pass in 0..<2 {
                    let targets = hosts.filter { ip in !self.devices.contains(where: { $0.ip == ip }) }
                    for offset in stride(from: 0, to: targets.count, by: 12) {
                        if Task.isCancelled || ContinuousClock.now >= deadline { break }
                        guard (try? WiFiSnapshot.current(path: self.monitor.currentPath)) == current else { self.stop(reason: "changed"); return }
                        let batch = Array(targets[offset..<min(offset + 12, targets.count)])
                        await withTaskGroup(of: Device?.self) { group in
                            for ip in batch {
                                group.addTask { await Self.probe(ip, pass: pass, deadline: deadline) }
                            }
                            for await device in group {
                                if !Task.isCancelled, self.runID == id, let device { self.upsert(device) }
                            }
                        }
                        completed += batch.count
                        self.progress = min(0.99, Double(completed) / Double(max(1, hosts.count * 2)))
                    }
                    if Task.isCancelled || ContinuousClock.now >= deadline { break }
                }
                // Give Bonjour a minimum discovery window on small subnets.
                let remaining = Duration.seconds(8) - start.duration(to: ContinuousClock.now)
                if !Task.isCancelled, remaining > .zero { try? await Task.sleep(for: remaining) }
                guard self.runID == id else { return }
                let complete = !Task.isCancelled && ContinuousClock.now < deadline
                self.finishScan(complete: complete)
            }
        } catch NetworkFailure.invalidSubnet { status = "subnet" }
        catch { status = "wifi" }
    }
    nonisolated private static func probe(_ ip: String, pass: Int, deadline: ContinuousClock.Instant) async -> Device? {
        let ports: [UInt16] = pass == 0 ? [80, 443, 445, 22, 9100, 62078] : [80, 443, 139, 135, 3389, 554, 8008, 8009]
        for port in ports {
            guard !Task.isCancelled, ContinuousClock.now < deadline else { return nil }
            let state = await TCPProbe().run(ip: ip, port: port, timeout: pass == 0 ? 0.4 : 0.65)
            if state != .noResponse { return Device(ip: ip, name: "", evidence: "TCP \(port): \(state.rawValue)") }
        }
        return nil
    }
    private func finishScan(complete: Bool) {
        discovery.stop(); busy = false; operation = nil
        status = complete ? "complete" : "partial"; progress = complete ? 1 : progress
        history.insert(ScanRecord(id: UUID(), date: Date(), subnet: subnet, count: devices.count, complete: complete), at: 0)
        history = Array(history.prefix(20)); save(history, key: "history"); persistDevices()
        snapshot = nil
    }
    func stop(reason: String = "cancelled") {
        guard busy else { return }
        let wasScan = status == "scanning"
        runID = UUID(); operation?.cancel(); operation = nil; discovery.stop()
        if wasScan { finishScan(complete: false) }
        busy = false; snapshot = nil; status = reason
    }
    func speed() {
        guard !busy else { return }
        do { snapshot = try WiFiSnapshot.current(path: monitor.currentPath) }
        catch { status = "wifi"; return }
        busy = true; status = "latency"
        let id = UUID(); runID = id
        operation = Task {
            do {
                let result = try await SpeedMeasurement.run { [weak self] phase in
                    if self?.runID == id { self?.status = phase }
                }
                guard runID == id, !Task.isCancelled else { return }
                speeds.insert(result, at: 0); speeds = Array(speeds.prefix(20)); save(speeds, key: "speeds"); status = "complete"
            } catch { if runID == id { status = "measurementError" } }
            if runID == id { busy = false; snapshot = nil; operation = nil }
        }
    }
    func ports(ip: String) {
        guard !busy, !stale else { return }
        do {
            let current = try WiFiSnapshot.current(path: monitor.currentPath)
            guard try current.subnet.contains(ip) else { status = "changed"; return }
            snapshot = current
        } catch { status = "wifi"; return }
        busy = true; status = "ports"; portResults = [:]
        let id = UUID(); runID = id
        operation = Task {
            let ports: [UInt16] = [21,22,23,25,53,80,110,139,143,443,445,554,3389,8008,8009,9100]
            for port in ports {
                guard !Task.isCancelled, runID == id else { return }
                let result = await TCPProbe().run(ip: ip, port: port)
                guard !Task.isCancelled, runID == id else { return }
                portResults[port] = result
            }
            guard runID == id else { return }
            busy = false; snapshot = nil; operation = nil; status = "complete"
        }
    }
    func clearRecords() {
        guard !busy else { return }
        devices = []; history = []; speeds = []; portResults = [:]; stale = false; subnet = "—"; status = "ready"
        ["devices", "history", "speeds"].forEach { defaults.removeObject(forKey: $0) }
    }
}
