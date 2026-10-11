import Foundation

/// In-memory cache with expiration (TTL) and deduplication of concurrent requests.
///
/// Why an `actor`? The cache is used by many Tasks at once.
/// The actor guarantees that `storage` is accessed by only one Task at a time
/// (serial access without manual locks / DispatchQueue) → no data race.
///
/// Deduplication: if two screens request product 5 at the same time, the second request
/// does not hit the network; it waits for the result of the first (`.loading(Task)`).
actor AsyncCache<Key: Hashable & Sendable, Value: Sendable> {
    private enum Entry {
        case loading(Task<Value, any Error>)
        case loaded(Value, expiresAt: ContinuousClock.Instant)
    }

    private var storage: [Key: Entry] = [:]
    private let timeToLive: Duration
    private let clock = ContinuousClock()

    init(timeToLive: Duration = .seconds(300)) {
        self.timeToLive = timeToLive
    }

    func value(
        for key: Key,
        loader: @escaping @Sendable () async throws -> Value
    ) async throws -> Value {
        switch storage[key] {
        case .loaded(let value, let expiresAt) where clock.now < expiresAt:
            return value
        case .loading(let task):
            return try await task.value
        case .loaded, nil:
            break
        }

        // Unstructured Task: it is not cancelled if the first caller is cancelled,
        // because the result may still be needed by other waiters.
        let task = Task { try await loader() }
        storage[key] = .loading(task)

        do {
            let value = try await task.value
            // ACTOR REENTRANCY: during the `await` above the actor may have served
            // other calls (for example `removeAll()`). The state may differ
            // from before the `await` — so we do not assume it is unchanged.
            storage[key] = .loaded(value, expiresAt: clock.now.advanced(by: timeToLive))
            return value
        } catch {
            // Errors are not cached — the next attempt will go to the network again.
            storage[key] = nil
            throw error
        }
    }

    func removeValue(for key: Key) {
        storage[key] = nil
    }

    func removeAll() {
        storage.removeAll()
    }
}
