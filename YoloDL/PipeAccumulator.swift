// Thread-safe Data collector for Process pipe callbacks.
// Uses NSLock to serialise appends from arbitrary threads, and exposes
// the accumulated Data and its UTF-8 string representation as properties
// safe to read from any isolation context.
//
// This helper is used from Process pipe callbacks, so it must not inherit
// the app target's default MainActor isolation.

import Foundation

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
