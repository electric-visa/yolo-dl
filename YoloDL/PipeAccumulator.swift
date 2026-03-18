import Foundation

// This helper is used from Process pipe callbacks, so it must not inherit
// the app target's default MainActor isolation.
nonisolated final class PipeAccumulator: @unchecked Sendable {
    private var buffer = Data()
    private let lock = NSLock()

    func append(_ data: Data) {
        lock.lock()
        buffer.append(data)
        lock.unlock()
    }

    var data: Data {
        lock.lock()
        defer { lock.unlock() }
        return buffer
    }

    var string: String {
        String(data: data, encoding: .utf8) ?? ""
    }
}
