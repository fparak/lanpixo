import Foundation

/// Ephemeral, non-cellular HTTPS transfers. Rejects redirects and overlong bodies.
final class BoundedHTTP: NSObject, URLSessionDataDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<Int, Error>?
    private var session: URLSession?
    private var task: URLSessionDataTask?
    private var count = 0
    private var limit = 0
    private var ended = false

    func perform(_ request: URLRequest, responseLimit: Int) async throws -> Int {
        try await withTaskCancellationHandler(operation: {
            try await withCheckedThrowingContinuation { completion in
                let config = URLSessionConfiguration.ephemeral
                config.allowsCellularAccess = false
                config.allowsExpensiveNetworkAccess = false
                config.urlCache = nil; config.httpCookieStorage = nil
                config.timeoutIntervalForRequest = 8; config.timeoutIntervalForResource = 12
                let activeSession = URLSession(configuration: config, delegate: self, delegateQueue: nil)
                let activeTask = activeSession.dataTask(with: request)
                lock.lock()
                if ended { lock.unlock(); activeSession.invalidateAndCancel(); completion.resume(throwing: CancellationError()); return }
                limit = responseLimit; continuation = completion; session = activeSession; task = activeTask
                lock.unlock()
                activeTask.resume()
            }
        }, onCancel: { self.finish(.failure(CancellationError())) })
    }
    private func finish(_ result: Result<Int, Error>) {
        lock.lock()
        guard !ended else { lock.unlock(); return }
        ended = true
        let completion = continuation; continuation = nil
        let active = session; session = nil; task = nil
        lock.unlock()
        active?.invalidateAndCancel(); completion?.resume(with: result)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let response = response as? HTTPURLResponse, [200, 204].contains(response.statusCode),
              response.expectedContentLength <= Int64(limit) else {
            completionHandler(.cancel); finish(.failure(NetworkFailure.http)); return
        }
        completionHandler(.allow)
    }
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        count += data.count
        if count > limit { finish(.failure(NetworkFailure.bodySize)) }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error { finish(.failure(error)) } else { finish(.success(count)) }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil); finish(.failure(NetworkFailure.http))
    }
}

enum SpeedMeasurement {
    static func run(update: @escaping @MainActor @Sendable (String) -> Void) async throws -> SpeedResult {
        let clock = ContinuousClock()
        let deadline = clock.now.advanced(by: .seconds(60))
        let base = "https://fra.speedtest.clouvider.net/backend"
        var transferred = 0
        func transfer(path: String, upload: Int = 0, expected: Int? = nil) async throws -> Double {
            try Task.checkCancellation()
            guard clock.now < deadline else { throw NetworkFailure.cancelled }
            let separator = path.contains("?") ? "&" : "?"
            var request = URLRequest(url: URL(string: base + path + separator + "lanpixo=" + UUID().uuidString)!)
            request.cachePolicy = .reloadIgnoringLocalCacheData
            request.setValue("identity", forHTTPHeaderField: "Accept-Encoding")
            request.setValue("no-store", forHTTPHeaderField: "Cache-Control")
            if upload > 0 {
                request.httpMethod = "POST"
                // Bounded random payload; compression cannot inflate the throughput result.
                var bytes = [UInt8](repeating: 0, count: upload)
                for index in bytes.indices { bytes[index] = UInt8.random(in: 0...255) }
                request.httpBody = Data(bytes)
                request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
            }
            let start = clock.now
            let received = try await BoundedHTTP().perform(request, responseLimit: expected ?? 16_384)
            if let expected, received != expected { throw NetworkFailure.bodySize }
            transferred += received + upload
            let components = start.duration(to: clock.now).components
            return max(0.000001, Double(components.seconds) + Double(components.attoseconds) / 1e18)
        }
        await update("latency")
        _ = try await transfer(path: "/empty.php")
        var samples: [Double] = []
        for _ in 0..<5 { samples.append(try await transfer(path: "/empty.php") * 1000) }
        await update("download")
        let count = 4_194_304
        let downloadTime = try await transfer(path: "/garbage.php?ckSize=4", expected: count)
        await update("upload")
        let uploadCount = 1_000_000
        let uploadTime = try await transfer(path: "/empty.php", upload: uploadCount)
        try Task.checkCancellation()
        return SpeedResult(download: Double(count) * 8 / downloadTime / 1e6, upload: Double(uploadCount) * 8 / uploadTime / 1e6, latency: samples.sorted()[2], bytes: transferred)
    }
}
