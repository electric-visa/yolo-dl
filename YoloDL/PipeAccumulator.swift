import Foundation

final class PipeAccumulator: @unchecked Sendable {
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
