//
//  TestHelpers.swift
//  Internet ArchiveTests
//
//  Shared test helper utilities
//

import Foundation

/// Thread-safe counter for testing async operations
final class AtomicCounter: @unchecked Sendable {
    private var _value: Int = 0
    private let lock = NSLock()

    var value: Int {
        lock.lock()
        defer { lock.unlock() }
        return _value
    }

    func increment() {
        lock.lock()
        defer { lock.unlock() }
        _value += 1
    }

    func reset() {
        lock.lock()
        defer { lock.unlock() }
        _value = 0
    }
}
